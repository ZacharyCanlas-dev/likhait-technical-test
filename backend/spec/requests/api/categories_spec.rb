require 'rails_helper'

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    let!(:food) { Category.create!(name: "Food") }
    let!(:transport) { Category.create!(name: "Transport") }
    let!(:supplies) { Category.create!(name: "Supplies") }

    it "returns all categories" do
      get "/api/categories"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |c| c["name"] }).to include("Food", "Transport", "Supplies")
    end

    it "returns categories in alphabetical order" do
      get "/api/categories"

      json = JSON.parse(response.body)
      expect(json.map { |c| c["name"] }).to eq([ "Food", "Supplies", "Transport" ])
    end
  end

  describe "POST /api/categories" do
    def post_category(name, icon: nil)
      post "/api/categories", params: { category: { name: name, icon: icon } }, as: :json
    end

    context "with a valid category" do
      it "persists it and returns 201" do
        expect { post_category("Groceries", icon: "🛒") }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(Category.last.icon).to eq("🛒")
      end

      it "returns the category in the shape the index returns" do
        post_category("Groceries", icon: "🛒")
        created = JSON.parse(response.body)

        get "/api/categories"
        listed = JSON.parse(response.body).find { |category| category["name"] == "Groceries" }

        expect(created).to eq(listed)
        expect(created["id"]).to eq(Category.last.id)
      end

      it "accepts a category with no icon" do
        post_category("Groceries")

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["icon"]).to be_nil
      end
    end

    context "with a rejected category" do
      it "answers with the same error envelope the expenses endpoint uses" do
        expect { post_category("") }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Name can't be blank")
      end

      it "reports a duplicate name" do
        Category.create!(name: "Groceries")

        expect { post_category("Groceries") }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Name has already been taken")
      end

      it "reports a rejected icon" do
        expect { post_category("Groceries", icon: "not an icon") }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Icon must be a single character")
      end
    end

    context "with a malformed request" do
      it "answers a missing category key with 400" do
        post "/api/categories", params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "ignores attributes that are not permitted" do
        other = Category.create!(name: "Other")

        post "/api/categories", params: { category: { name: "Groceries", id: other.id } }, as: :json

        expect(response).to have_http_status(:created)
        expect(Category.last.id).not_to eq(other.id)
      end
    end

    context "when a concurrent request wins the unique index" do
      # Only the validator is suppressed, so the INSERT still reaches the real
      # unique index. This covers the constraint together with the rescue.
      it "answers with 422 rather than raising" do
        Category.create!(name: "Groceries")
        allow_any_instance_of(ActiveRecord::Validations::UniquenessValidator)
          .to receive(:validate_each)

        expect { post_category("Groceries") }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Name has already been taken")
      end
    end
  end
end
