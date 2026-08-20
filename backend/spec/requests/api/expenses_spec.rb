require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  def response_ids
    JSON.parse(response.body).map { |expense| expense["id"] }
  end

  def expense_on(date)
    Expense.create!(description: "Expense", amount: 10.00, category: food_category, date: date)
  end

  describe "GET /api/expenses" do
    context "with expenses on different dates" do
      # Entered first but spent more recently, so insertion order and
      # expense-date order disagree. Fixtures sharing a date could not
      # distinguish them.
      let!(:recent_expense) { Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.new(2026, 2, 10)) }
      let!(:older_expense) { Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.new(2026, 2, 5)) }

      it "returns all expenses with category information" do
        get "/api/expenses"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json.map { |expense| expense["category"] }).to contain_exactly("Food", "Transport")
      end

      it "returns expenses in descending order by expense date" do
        get "/api/expenses"

        expect(response_ids).to eq([ recent_expense.id, older_expense.id ])
      end
    end

    context "with expenses sharing a date" do
      # `created_at` is deliberately inverted against insertion order, so an
      # ordering that tie-breaks on `created_at` instead of `id` fails here.
      let!(:entered_first) do
        Expense.create!(description: "Breakfast", amount: 10.00, category: food_category,
                        date: Date.new(2026, 2, 5), created_at: Time.utc(2026, 6, 1))
      end
      let!(:entered_second) do
        Expense.create!(description: "Dinner", amount: 20.00, category: food_category,
                        date: Date.new(2026, 2, 5), created_at: Time.utc(2026, 1, 1))
      end

      it "breaks ties on a shared date by insertion order, newest first" do
        get "/api/expenses"

        expect(response_ids).to eq([ entered_second.id, entered_first.id ])
      end
    end

    context "with a month filter" do
      # Spent in February, entered in August: `date` and `created_at` disagree
      # about which month this row belongs to, so the filter has to pick one.
      let!(:backdated_expense) do
        Expense.create!(description: "Backdated groceries", amount: 42.00, category: food_category,
                        date: Date.new(2026, 2, 5), created_at: Time.utc(2026, 8, 20, 12, 0, 0))
      end

      # The range has to be inclusive at both ends, must not spill into the
      # neighbouring months, and must not match February of a different year.
      let!(:first_of_month) { expense_on(Date.new(2026, 2, 1)) }
      let!(:last_of_month) { expense_on(Date.new(2026, 2, 28)) }
      let!(:day_before_month) { expense_on(Date.new(2026, 1, 31)) }
      let!(:day_after_month) { expense_on(Date.new(2026, 3, 1)) }
      let!(:same_month_previous_year) { expense_on(Date.new(2025, 2, 5)) }

      it "includes an expense in the month the money was spent" do
        get "/api/expenses", params: { year: 2026, month: 2 }

        expect(response).to have_http_status(:success)
        expect(response_ids).to include(backdated_expense.id)
      end

      it "excludes an expense from the month it was merely entered in" do
        get "/api/expenses", params: { year: 2026, month: 8 }

        expect(response_ids).to be_empty
      end

      it "includes the first and last day of the requested month" do
        get "/api/expenses", params: { year: 2026, month: 2 }

        expect(response_ids).to include(first_of_month.id, last_of_month.id)
      end

      it "excludes the days on either side of the requested month" do
        get "/api/expenses", params: { year: 2026, month: 2 }

        expect(response_ids).not_to include(day_before_month.id, day_after_month.id)
      end

      it "excludes the same month of a different year" do
        get "/api/expenses", params: { year: 2026, month: 2 }

        expect(response_ids).not_to include(same_month_previous_year.id)
      end
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.current
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq("150.5")
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.current
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.current
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
