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
