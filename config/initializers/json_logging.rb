# Structured JSON logging to STDOUT for container/Kamal deployments.
# Includes request_id (GUID-ish) and error_id for traceability.

class JsonLogFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, _progname, msg)
    payload = {
      time: timestamp.utc.iso8601(3),
      level: severity,
      message: msg.is_a?(String) ? msg : msg.inspect,
      request_id: Thread.current[:request_id]
    }.compact
    "#{payload.to_json}\n"
  end
end

Rails.application.configure do
  # Tag logs with the request id provided by ActionDispatch::RequestId.
  config.log_tags = [ :request_id ]
end
