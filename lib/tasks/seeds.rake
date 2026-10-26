namespace :seeds do
  desc "Purge used/expired auth seeds older than DAYS (default 1). Usage: bin/rails seeds:purge [DAYS=1]"
  task purge: :environment do
    days = (ENV["DAYS"] || "1").to_i
    cutoff = Time.current - days.days
    count = AuthSeed.where("usado = ? OR expira < ?", true, Time.current).where("created_at < ?", cutoff).delete_all
    puts "Purged #{count} auth seeds older than #{days} day(s)."
  end
end
