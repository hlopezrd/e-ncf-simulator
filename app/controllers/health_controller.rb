class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "e-cf-simulator", timestamp: Time.current.iso8601 }
  end
end
