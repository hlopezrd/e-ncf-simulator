namespace :certificates do
  desc "Register a certificate for an RNC from a PEM/CRT file. Usage: bin/rails certificates:register RNC=... FILE=... [ALIAS=...]"
  task register: :environment do
    rnc = ENV.fetch("RNC")
    file = ENV.fetch("FILE")
    alias_name = ENV["ALIAS"]

    pem = File.read(file)

    cert = Certificate.new(rnc: rnc, alias_name: alias_name, certificate_pem: pem, active: true)

    Certificate.transaction do
      Certificate.where(rnc: rnc, active: true).update_all(active: false)
      cert.save!
    end

    puts "Registered certificate ##{cert.id} for RNC #{rnc}"
    puts "  thumbprint: #{cert.thumbprint}"
    puts "  vigente:    #{cert.vigente?} (#{cert.not_before} -> #{cert.not_after})"
  end
end
