module Tracking
  # Un solo registro por usuario por día: crea el de hoy si no existe, o lo
  # actualiza si ya existe (soporta tanto "Guardar Registro" como "Editar
  # datos" en /seguimiento con la misma llamada).
  class Upsert
    attr_reader :entry, :error, :errors, :created

    def self.call(user:, params:)
      new(user:, params:).call
    end

    def initialize(user:, params:)
      @user = user
      @params = params || {}
      @entry = nil
      @error = nil
      @errors = {}
      @created = false
    end

    def call
      return failure("User is required") unless @user

      @entry = @user.tracking_entries.find_or_initialize_by(recorded_on: Date.current)
      @created = @entry.new_record?
      @entry.assign_attributes(entry_attributes)

      unless @entry.save
        @errors = @entry.errors.to_hash
      end

      self
    rescue StandardError => e
      @error = "Error saving tracking entry: #{e.message}"
      self
    end

    def success?
      @error.nil? && @entry&.persisted?
    end

    private

    def failure(message)
      @error = message
      self
    end

    def entry_attributes
      @params.slice(:weight_kg, :waist_cm, :mood, :energy_level, :habits_completed)
    end
  end
end
