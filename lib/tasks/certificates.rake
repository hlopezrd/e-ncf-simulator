namespace :certificates do
  desc "Register a certificate for an RNC from a PEM/CRT file. Usage: bin/rails certificates:register RNC=... FILE=... [ALIAS=...]"
  task register: :environment do
    puts "AVISO: este task es solo para bootstrap/deploy. El flujo normal es desde el portal admin (Empresas)."
    rnc = ENV.fetch("RNC")
    file = ENV.fetch("FILE")
    alias_name = ENV["ALIAS"]

    pem = File.read(file)

    company = Company.find_or_create_by!(rnc: rnc) do |c|
      c.razon_social = "Empresa #{rnc}"
      c.activa = true
    end

    cert = Certificate.new(rnc: rnc, company: company, alias_name: alias_name, certificate_pem: pem, active: true)

    Certificate.transaction do
      Certificate.where(rnc: rnc, active: true).update_all(active: false)
      cert.save!
    end

    puts "Registered certificate ##{cert.id} for RNC #{rnc}"
    puts "  thumbprint: #{cert.thumbprint}"
    puts "  vigente:    #{cert.vigente?} (#{cert.not_before} -> #{cert.not_after})"
  end
end
