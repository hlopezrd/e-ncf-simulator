require "rails_helper"

RSpec.describe "Health", type: :request do
  it "GET /health returns 200" do
    get "/health"
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["status"]).to eq("ok")
  end
end
