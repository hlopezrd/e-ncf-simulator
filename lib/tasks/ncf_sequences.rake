namespace :ncf_sequences do
  desc "Register an e-NCF range for an RNC. Usage: bin/rails ncf_sequences:register RNC=... TIPO=31 DESDE=1 HASTA=1000 [VENCIMIENTO=2027-12-31]"
  task register: :environment do
    puts "AVISO: este task es solo para bootstrap/deploy. El flujo normal es desde el portal admin (Empresas)."
    rnc = ENV.fetch("RNC")
    tipo = ENV.fetch("TIPO", "31").to_i
    desde = ENV.fetch("DESDE", "1").to_i
    hasta = ENV.fetch("HASTA", "1000").to_i
    venc = ENV.fetch("VENCIMIENTO", (Date.current + 365).to_s)
    company = Company.find_or_create_by!(rnc: rnc) do |c|
      c.razon_social = "Empresa #{rnc}"
      c.activa = true
    end
    seq = NcfSequence.create!(rnc: rnc, company: company, tipo: tipo, desde: desde, hasta: hasta, fecha_vencimiento: Date.parse(venc), activa: true)
    puts "Registered NCF sequence ##{seq.id} for RNC #{rnc} type #{tipo}: #{desde}..#{hasta} (vence #{seq.fecha_vencimiento})"
  end
end
