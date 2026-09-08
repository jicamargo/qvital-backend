module Colombia
  # Valida que una shipping_address tenga un departamento y una ciudad
  # válidos de Colombia, y una localidad/comuna cuando la ciudad
  # seleccionada tiene subdivisiones (Bogotá D.C., Medellín, Cali...).
  #
  # Copia server-side de los mismos catálogos que usa el frontend para los
  # selects del checkout (`qvital-frontend/lib/data/colombia-locations.json`
  # y `colombia-localidades.json`) — mantener ambos en sync a mano si cambian.
  class AddressValidator
    LOCATIONS_PATH = Rails.root.join("app/services/colombia/locations.json")
    LOCALIDADES_PATH = Rails.root.join("app/services/colombia/localidades.json")

    def self.call(shipping_address)
      new(shipping_address).call
    end

    class << self
      def locations
        @locations ||= JSON.parse(File.read(LOCATIONS_PATH))
      end

      def localidades
        @localidades ||= JSON.parse(File.read(LOCALIDADES_PATH))
      end
    end

    def initialize(shipping_address)
      @address = (shipping_address || {}).to_h.with_indifferent_access
    end

    # @return [Array<String>] errores encontrados, vacío si la dirección es válida.
    def call
      errors = []

      departamento = @address[:state].to_s.strip
      ciudad = @address[:city].to_s.strip
      localidad = @address[:locality].to_s.strip

      if departamento.blank?
        errors << "El departamento es obligatorio"
      elsif !departamentos.include?(departamento)
        errors << "El departamento '#{departamento}' no es válido"
      end

      validate_ciudad!(errors, departamento:, ciudad:)
      validate_localidad!(errors, ciudad:, localidad:)

      errors
    end

    private

    def validate_ciudad!(errors, departamento:, ciudad:)
      if ciudad.blank?
        errors << "La ciudad es obligatoria"
      elsif departamentos.include?(departamento) && !ciudades_de(departamento).include?(ciudad)
        errors << "La ciudad '#{ciudad}' no pertenece al departamento '#{departamento}'"
      end
    end

    def validate_localidad!(errors, ciudad:, localidad:)
      localidades_validas = localidades_de(ciudad)
      return if localidades_validas.empty?

      if localidad.blank?
        errors << "La localidad/comuna es obligatoria para #{ciudad}"
      elsif !localidades_validas.include?(localidad)
        errors << "La localidad/comuna '#{localidad}' no es válida para #{ciudad}"
      end
    end

    def departamentos
      self.class.locations.map { |d| d["departamento"] }
    end

    def ciudades_de(departamento)
      self.class.locations.find { |d| d["departamento"] == departamento }&.fetch("ciudades", []) || []
    end

    def localidades_de(ciudad)
      self.class.localidades.find { |c| c["ciudad"] == ciudad }&.fetch("localidades", []) || []
    end
  end
end
