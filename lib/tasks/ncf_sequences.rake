namespace :ncf_sequences do
  desc "Register an e-NCF range for an RNC. Usage: bin/rails ncf_sequences:register RNC=... TIPO=31 DESDE=1 HASTA=1000 [VENCIMIENTO=2027-12-31]"
  task register: :environment do
    rnc = ENV.fetch("RNC")
    tipo = ENV.fetch("TIPO", "31").to_i
    desde = ENV.fetch("DESDE", "1").to_i
    hasta = ENV.fetch("HASTA", "1000").to_i
    venc = ENV.fetch("VENCIMIENTO", (Date.current + 365).to_s)
    seq = NcfSequence.create!(rnc: rnc, tipo: tipo, desde: desde, hasta: hasta, fecha_vencimiento: Date.parse(venc), activa: true)
    puts "Registered NCF sequence ##{seq.id} for RNC #{rnc} type #{tipo}: #{desde}..#{hasta} (vence #{seq.fecha_vencimiento})"
  end
end
