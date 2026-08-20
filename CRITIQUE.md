# Codebase review

Notes from a full pass over this repository, written against README §5. Findings that were worth
fixing became pull requests; the rest are here, with the mechanism in each case rather than the
symptom.

Every claim in this document was reproduced against the running application; where a prediction
differed from the measurement, the measurement is recorded.

## What became a pull request

| # | Finding | Kind |
|---|---|---|
| 5 | The repository cannot start from a clean checkout — five independent defects between `git clone` and a served request | Infrastructure |
| 6 | Expense dates render, and save, one day early at any negative UTC offset | Correctness — data loss |
| 7 | CORS allowed every origin every method on every path | Security |
| 8 | Changing an expense's category returned 200 and did nothing | Correctness |
| 9 | `GET /api/expenses` returned 500 for an impossible month, returned every row unbounded, and had no index for its ordering | Robustness, performance |
| 10 | No component in `vibes/` had accessibility support, so every modal and field in the app inherited the same defects | Architectural |
| 11 | The test harness was present in the `Gemfile` and configured nowhere; `Expense` validated almost nothing | Code quality |

## Blocked, not skipped

**CI has never run on this repository, and relocating it needs one command only the repository owner
can issue.** The workflow lives at `backend/.github/workflows/ci.yml`. GitHub reads
`.github/workflows/` at the repository root only, so no job has executed against any commit or pull
request here. Moving it also requires three corrections: the test step is
`bin/rails db:test:prepare test test:system` — Minitest, while this project uses RSpec and has no
`test/` directory; `DATABASE_URL` names no database; and no job sets `working-directory: backend`,
where the application actually lives.

The move itself is blocked on a token scope. A commit touching `.github/workflows/` is rejected at
push time unless the credential carries the `workflow` scope. The remedy is one command:

```bash
gh auth refresh -s workflow
```

**One claim in the pull requests rests on reasoning rather than execution.** PR #5 fixes five
defects that prevent `docker compose up` from reaching a running application. Each was reproduced
before being fixed, and everything verifiable without the Docker daemon has been verified — but the
integrated boot has not been run end to end, because starting the daemon would bind `:3306` against
a MySQL instance already serving the host. This is stated in #5 and repeated here so it is visible
in the summary as well as in the diff. Running `docker compose up` from a clean clone of that branch
is the one outstanding verification.

## Architectural flaws

**There is no authentication or authorisation anywhere.** Every endpoint is open, and the data model
has no concept of a user — expenses belong to nobody, so "whose expenses" is not a question the
schema can answer. This is the largest finding in the review and it is deliberately not attempted:
it is a product decision rather than a defect fix, and implementing it rewrites every controller,
every spec and the schema.

**Deleting a category destroys its entire expense history.** `Category has_many :expenses, dependent:
:destroy` (`app/models/category.rb`). `db/init.sql` declared the opposite intent on the same
relationship — `ON DELETE RESTRICT` — so the two layers already disagreed about what should happen.
No destroy action exists today, which is why this is a note rather than a fix; user-created
categories make it reachable the moment one is added. `dependent: :restrict_with_error` is the right
setting when that endpoint lands.

**Serialization is hand-built inside the controller.** `Api::ExpensesController#format_expense`
assembles the response hash by hand and casts `amount` with `.to_f`. Every payload change has to be
made there and mirrored into `frontend/src/types.ts` manually, with nothing enforcing that the two
agree. That gap is not hypothetical: it produced the defect in PR #8, where the payload carried a
category *name* and the endpoint accepted a category *id*. A serializer layer is the standard
answer; introducing one for two models is more architecture than this codebase has earned, so the
coupling is named rather than removed.

**The category list had four sources of truth.** `db/seeds.rb` (ten), a duplicated constant in the
client (the same ten), an emoji map (nine — `Personal` was missing), and `db/init.sql` (five
entirely different ones). `README.md` listed a fifth set. Three of the four are collapsed by the
category-management work and PR #5; this is recorded because it is the root cause those two share.

**There is no frontend test infrastructure at all.** `frontend/package.json` has three scripts and
no vitest, jest, testing-library or playwright. `npm run build` — which runs `tsc` first — is the
only automated check that has ever existed on client code. Two of the defects found in this review
were client-side and would each have been caught by a single unit test: the timezone parsing in #6
and the payload key in #8. Standing up Vitest is the highest-value follow-up in these notes.

## Security

**Rails 7.2.3 reached end of support on 2026-08-09.** No further security patches ship for this
branch. It is Brakeman's only warning on this codebase:

```
Unmaintained Dependency | Support for Rails 7.2.3 ended on 2026-08-09 | Gemfile.lock:176
```

An 8.x upgrade is a dependency-tree change with no meaningful way to verify it against a suite of
this size, so it is recommended rather than attempted.

**A clean static scan is not evidence that an API is safe.** Brakeman reported no finding on the
`origins "*"` CORS configuration fixed in PR #7, because it does not model `rack-cors` at all. Worth
stating because the scan output otherwise reads as a verdict.

**`config.hosts` is unset**, so DNS-rebinding protection is off in production. Setting it requires
knowing the deployment hostname, which this repository does not.

**There is no rate limiting**, and no obvious place in this project to put it.

## Correctness, below the bar for a pull request

**`bin/rails db:schema:load` cannot be run on this repository.** `db/schema.rb` uses
`create_table ... force: :cascade`, which the mysql2 adapter emits as a plain `DROP TABLE`; MySQL
refuses to drop `categories` while `expenses` holds a foreign key to it:

```
Mysql2::Error: Cannot drop table 'categories' referenced by a foreign key constraint
'fk_rails_06966d0da0' on table 'expenses'
```

It fails even against a freshly created database, because `config/database.yml` hardcodes
`test: expense_system_test` and only `development` honours the `DATABASE_NAME` variable — so the task
targets the test database as well, and dies there. `schema.rb` is generated by Rails, so there is no
line in this repository to correct. Use `db:prepare`, or `db:drop db:create db:schema:load`.

**Client-side pagination strands the user on a blank table.** `CalendarExpenseTable` never resets
`currentPage` when `expenses` changes. Sit on page 3, switch to a month with ten or fewer expenses:
the slice is empty so the table body renders blank, and `Pagination` returns `null` at
`totalPages <= 1`, so the controls that would let you navigate back are gone. The only escape is
changing month again or reloading. The fix is a two-line `useEffect`; it is here rather than in a
pull request because it has no narrative worth a reviewer's time.

**Failures are invisible, in three different ways.** A failed create or update is `console.error`'d
and nothing else, so the modal stays open with no message. A failed delete calls `alert()`. Three
non-answers to one problem. Introducing an error surface is a design decision this codebase has not
made anywhere else, which is why it is a note.

**`:unprocessable_entity` is deprecated in Rack 3.1** and both controllers use it. Every spec run
now prints the warning. `:unprocessable_content` replaces it.

## Optimization

**`db/seeds.rb` is non-deterministic and deletes row by row.** `rand(3..8)` per day with no seeded
RNG, roughly 4,300 individual `INSERT`s, and a `destroy_all` prologue that instantiates every
existing row in order to delete it. `insert_all` with a fixed `srand` would make the dataset both
fast and reproducible across machines. PR #5 fixes the half that mattered — the seed ran on *every*
container start, so a restart destroyed anything entered through the UI — and leaves the rest, which
is a large diff on a development-only file.

**The seeds set `created_at` from `date`**, so the two columns agree on every seeded row. That is
why BUG-001 was invisible in the demo data and appeared only once a real expense was entered.

**Dead code, exported and never imported.** Types `MonthlySummary`, `TopCategory`, and the
`CategoryBreakdown` *type* — the component of that name defines its own local shape and ignores it.
Functions `calculateTotal`, `getDaysInMonth`, `groupExpensesByDay`. Components `ItemTable`,
`ColumnBase`, `FormControl` and `QuickAddButton`, all exported and imported by nothing, while
`CalendarExpenseTable` hand-rolls its own `<table>`. `api.ts`'s exported `fetchExpenses`, which
`HistoryPage` shadows with a local function of the same name. `react-router-dom`, a dependency with
zero imports — `App.tsx` switches on a `currentPage` string that only ever holds `"history"`.
`faker` and `database_cleaner-active_record`, neither referenced. And `index.html` links
`/vite.svg`, which is not in the repository — a 404 on every page load.

**Container hygiene.** `docker-compose.yml` declares the obsolete `version: "3.8"` key.
`frontend/Dockerfile` runs `npm install` rather than `npm ci`, so the lockfile is advisory during the
image build — which is how the platform-specific lockfile defect stayed hidden as long as it did.
`node:18-alpine` is past end of life. Both services' `COPY . .` layers are masked immediately by the
bind mounts compose lays over them, so the image build does work that never runs. The backend has no
healthcheck, and `frontend` depends on it without a condition.

## Remaining work

**Focus the first invalid control after a failed submit.** The future-date work sets `noValidate` on
the expense form, which turns off the browser's own behaviour of moving focus to the first invalid
control. PR #10 ships the capability that restores it — an id, the aria wiring and a forwarded ref on
both `TextField` and `SelectBox` — but the wiring that consumes it lives in `ExpenseForm`, which two
unmerged branches modify: one adds the `noValidate` this responds to, the other renames the field the
form keys on. It lands cleanly once both merge, and not before.

**Stand up Vitest.** See *no frontend test infrastructure* above. This is the recommendation with the
best ratio of effort to defects prevented.

**A dependency pass.** `faker` and `database_cleaner-active_record` are unused; `react-router-dom` is
unused; Rails is out of support. Grouping them is better than removing one at a time, because each
removal regenerates `Gemfile.lock` or `package-lock.json`.
