# CORS configuration driven by environment.
# Set CORS_ORIGINS as a comma-separated list of allowed origins.
# Empty by default (no cross-origin access).

origins = ENV.fetch("CORS_ORIGINS") { "" }.split(",").map(&:strip).reject(&:blank?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: false
  end
end if origins.any?
