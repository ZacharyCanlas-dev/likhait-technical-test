require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  def response_ids
    JSON.parse(response.body).map { |expense| expense["id"] }
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
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
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
            date: Date.today
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
            date: Date.today
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
