require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
  let!(:expense1) { Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.today) }
  let!(:expense2) { Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.today) }

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns expenses in descending order by created_at" do
      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(expense2.id)
      expect(json.last["id"]).to eq(expense1.id)
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

  describe "PUT /api/expenses/:id" do
    let!(:expense) do
      Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.new(2026, 2, 5))
    end

    def put_expense(params)
      put "/api/expenses/#{expense.id}", params: { expense: params }, as: :json
    end

    it "changes the category" do
      put_expense(category_id: transport_category.id)

      expect(response).to have_http_status(:success)
      expect(expense.reload.category).to eq(transport_category)
    end

    it "changes the description, amount and date" do
      put_expense(description: "Dinner", amount: 42.50, date: "2026-02-09")

      expect(response).to have_http_status(:success)
      expect(expense.reload).to have_attributes(
        description: "Dinner",
        amount: 42.50,
        date: Date.new(2026, 2, 9)
      )
    end

    it "rejects a category that does not exist" do
      put_expense(category_id: 0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(expense.reload.category).to eq(food_category)
    end
  end

  describe "the expense payload" do
    let!(:expense) do
      Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.new(2026, 2, 5))
    end

    it "carries category_id alongside the display name" do
      get "/api/expenses"

      json = JSON.parse(response.body).first
      expect(json["category"]).to eq("Food")
      expect(json["category_id"]).to eq(food_category.id)
    end
  end
end
