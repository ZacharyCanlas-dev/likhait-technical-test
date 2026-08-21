# Codebase review

Notes from a full pass over this repository, written against README §5. Findings that were worth
fixing became pull requests; the rest are here, with the mechanism in each case rather than the
symptom.

Every claim about this codebase's behaviour was reproduced against the running application; where a
prediction differed from the measurement, the measurement is recorded.

## What became a pull request

| # | Finding | Kind |
|---|---|---|
| 1 | A pre-existing spec asserted `amount` as the string `"150.5"` while `format_expense` emits a JSON number, so the suite shipped one failing example | Tests |
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

CI is now the only blocked item. PR #5's integrated `docker compose up` has been run in both
directions from clean clones, and the full output is in #5: on `main` the build fails at `yaml.h not found` while
installing psych, which is a Dockerfile layer, so no container is ever created; on the branch the
stack comes up, `GET /api/expenses` answers 200 over 4,314 seeded records, and Vite serves on
`:5173`. The measurement also settled a detail reasoning had left open — a clean clone of `main`
never reaches the `rollup-linux-x64-musl` defect at all, because the backend image fails first.

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
category-management work, #3, and PR #5; this is recorded because it is the root cause those two share.

**There is no frontend test infrastructure at all.** `frontend/package.json` has three scripts and
no vitest, jest, testing-library or playwright. `npm run build` — which runs `tsc` first — is the
only automated check that has ever existed on client code. Two of the defects found in this review
were client-side and would each have been caught by a single unit test: the timezone parsing in #6
and the payload key in #8. Vitest and Cypress were both considered as the remedy; the comparison and
the reasoning behind choosing Vitest are under *Remaining work* below.

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
changing month again or reloading. The fix is a two-line `useEffect`, and it is exactly the kind of
state-reset bug a component test pins and review misses; it goes with the frontend test
infrastructure recommended below rather than landing untested.

**Failures were invisible, in three different ways.** A failed create or update was `console.error`'d
and nothing else, so the modal stayed open with no message; the future-date work, #4, gives both
writes an error surface rendered with `role="alert"`. A failed delete still calls `alert()`. What
remains is that the application has no single answer to reporting a failed write, which is a design
decision rather than a defect.

**`:unprocessable_entity` is deprecated in Rack 3.1** and both controllers use it. The warning
surfaces through rspec-rails' `have_http_status` matcher rather than the controller's render, so it
appears on the branches whose specs assert a 422 and not on `main`, which asserts none. The specs
have moved to `:unprocessable_content`; the controllers have not.

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

**Focus the first invalid control after a failed submit.** The future-date work, #4, sets `noValidate` on
the expense form, which turns off the browser's own behaviour of moving focus to the first invalid
control. PR #10 ships the capability that restores it — an id, the aria wiring and a forwarded ref on
both `TextField` and `SelectBox` — but the wiring that consumes it lives in `ExpenseForm`, which two
unmerged branches modify: one adds the `noValidate` this responds to, the other renames the field the
form keys on. It lands cleanly once both merge, and not before.

**Stand up Vitest rather than Cypress.** See *no frontend test infrastructure* above. Both were
considered, and the deciding factor is that neither client-side defect this review found is a flow.
#6 is a pure function — a `YYYY-MM-DD` string in, a `Date` out — and #8 is the shape of a request
body. A test that never renders a page catches both. Cypress earns its cost on assembled journeys
through a real browser; paying that to catch a date-parsing bug is the wrong instrument.

Three practical points reinforce it. Vitest reuses the Vite config, transform pipeline and TypeScript
resolution this project already has, so it arrives as one devDependency and a `test` script rather
than a second toolchain. Cypress needs Rails on `:3000` and a seeded MySQL for any spec worth
writing — which is exactly the infrastructure that did not work from a clean checkout until #5, and a
test layer that runs only once infrastructure is healthy is the first thing to be skipped. And CI has
never executed against this repository at all; adding a browser binary and two services before a
suite that runs in one process on `npm test` inverts the order those should arrive in.

The argument against, stated because it is real: an end-to-end tool would have caught #8 the way a
user did — a save that reported success and changed nothing — whereas a unit test catches it only if
someone thinks to assert the request body. That advantage does not carry the cost here. If an
end-to-end layer is added later, Playwright fits this repository better than Cypress: it drives the
same flows, needs no separate dashboard tier, and is already present in the development environment.

Paired with `@testing-library/react`, Vitest also reaches the component behaviour PR #10 adds — the
focus trap, the restored focus, the label-to-input association — none of which needs a browser driver
to assert. That is the best ratio of effort to defects prevented in these notes.

**A dependency pass.** `faker` and `database_cleaner-active_record` are unused; `react-router-dom` is
unused; Rails is out of support. Grouping them is better than removing one at a time, because each
removal regenerates `Gemfile.lock` or `package-lock.json`.
