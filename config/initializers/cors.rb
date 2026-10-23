# CORS configuration.
# Allowed origins are checked against the `allowed_origins` table (maintained via admin panel).
# Falls back to the CORS_ORIGINS env var (comma-separated) when the table is empty or unavailable.

origin_checker = lambda do |origin, _env|
  begin
    if ActiveRecord::Base.connection.table_exists?(:allowed_origins) && AllowedOrigin.exists?(origin: origin)
      true
    else
      ENV.fetch("CORS_ORIGINS") { "" }.split(",").map(&:strip).include?(origin)
    end
  rescue StandardError
    ENV.fetch("CORS_ORIGINS") { "" }.split(",").map(&:strip).include?(origin)
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origin_checker
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: false
  end
end
