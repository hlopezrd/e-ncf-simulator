module Ecfs
  module XsdValidation
    MAX_XML_BYTES = 1.megabyte

    def self.validate(xml, xsd_file)
      return [ { codigo: "E011", campo: "xml", mensaje: "El XML excede el tamaño máximo permitido", severidad: "ERROR" } ] if xml.bytesize > MAX_XML_BYTES

      doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)
      schema_path = Rails.root.join("lib", "xsd", xsd_file)
      return [] unless File.exist?(schema_path)

      schema = cached_schema(xsd_file, schema_path)
      schema.validate(doc).map do |err|
        { codigo: "X001", campo: (err.path.presence || "xml"), mensaje: err.message.strip, severidad: "ERROR" }
      end
    rescue StandardError => e
      [ { codigo: "X000", campo: "xml", mensaje: "Error al cargar/validar XSD: #{e.message}", severidad: "ERROR" } ]
    end

    def self.cached_schema(xsd_file, schema_path)
      @cache ||= {}
      @cache[xsd_file] ||= begin
        raw = File.read(schema_path)
        raw = raw.gsub(/(name|type)="\s+/, '\\1="')
        Nokogiri::XML::Schema(raw)
      end
    end
  end
end
