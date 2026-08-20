require 'rails_helper'

RSpec.describe "CORS", type: :request do
  # Rack::Cors sits at the top of the middleware stack, so these examples assert
  # on response headers rather than on any controller's behaviour. The allowed
  # origin is the ALLOWED_ORIGINS default, since the variable is unset in test.
  let(:allowed_origin) { "http://localhost:5173" }
  let(:foreign_origin) { "http://attacker.example.com" }

  describe "a request from the configured origin" do
    it "is allowed" do
      get "/api/categories", headers: { "Origin" => allowed_origin }

      expect(response).to have_http_status(:success)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
    end

    it "passes preflight for a write method" do
      process :options, "/api/expenses", headers: {
        "Origin" => allowed_origin,
        "Access-Control-Request-Method" => "POST"
      }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
    end
  end

  describe "a request from any other origin" do
    it "receives no allow-origin header" do
      get "/api/categories", headers: { "Origin" => foreign_origin }

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end

    it "fails preflight for a write method" do
      process :options, "/api/expenses", headers: {
        "Origin" => foreign_origin,
        "Access-Control-Request-Method" => "POST"
      }

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end
end
