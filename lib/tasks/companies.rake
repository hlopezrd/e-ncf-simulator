namespace :companies do
  desc "Migrate existing RNCs into Company records and link them. Usage: bin/rails companies:migrate_from_rncs [DRY_RUN=true]"
  task migrate_from_rncs: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    rncs = Set.new
    [ Certificate, NcfSequence, User, ElectronicInvoice ].each do |klass|
      col = klass.column_names.include?("rnc_emisor") ? :rnc_emisor : :rnc
      klass.where.not(col => nil).pluck(col).each { |r| rncs << r }
    end

    puts "RNCs encontrados: #{rncs.size}"
    rncs.each do |rnc|
      company = Company.find_by(rnc: rnc)
      if company.nil?
        puts "#{dry_run ? '[DRY] ' : ''}Crear Company para RNC #{rnc}"
        unless dry_run
          company = Company.create!(rnc: rnc, razon_social: "Empresa #{rnc}", activa: true)
        end
      else
        puts "Company ya existe para RNC #{rnc} (id=#{company.id})"
      end

      next if dry_run

      Certificate.where(rnc: rnc, company_id: nil).update_all(company_id: company.id)
      NcfSequence.where(rnc: rnc, company_id: nil).update_all(company_id: company.id)
      User.where(rnc: rnc, company_id: nil).update_all(company_id: company.id)
      ElectronicInvoice.where(rnc_emisor: rnc, company_id: nil).update_all(company_id: company.id)
    end

    puts "Migración completada#{dry_run ? ' (dry run)' : ''}."
  end
end
