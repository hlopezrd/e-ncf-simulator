module Ecfs
  module XsdValidation
    def self.validate(xml, xsd_file)
      doc = Nokogiri::XML(xml)
      schema_path = Rails.root.join("lib", "xsd", xsd_file)
      return [] unless File.exist?(schema_path)

      raw = File.read(schema_path)
      raw = raw.gsub(/(name|type)="\s+/, '\\1="')
      schema = Nokogiri::XML::Schema(raw)
      schema.validate(doc).map do |err|
        { codigo: "X001", campo: (err.path.presence || "xml"), mensaje: err.message.strip, severidad: "ERROR" }
      end
    rescue StandardError => e
      [ { codigo: "X000", campo: "xml", mensaje: "Error al cargar/validar XSD: #{e.message}", severidad: "ERROR" } ]
    end
  end
end
