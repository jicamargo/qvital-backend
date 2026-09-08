module Tracking
  # Todo lo que /seguimiento necesita saber antes de mostrar el formulario:
  # - si es el primer registro del usuario (para el mensaje de bienvenida) y,
  #   si es así, su evaluación gratuita más reciente (mismo email) para
  #   poblar los campos iniciales (peso, perímetro abdominal).
  # - si ya existe un registro de hoy (para mostrar "ya registraste tus datos
  #   hoy" en vez del formulario, con opción de editarlo).
  class Prefill
    attr_reader :is_first_entry, :evaluation_lead, :today_entry, :error

    def self.call(user:)
      new(user:).call
    end

    def initialize(user:)
      @user = user
      @is_first_entry = false
      @evaluation_lead = nil
      @today_entry = nil
      @error = nil
    end

    def call
      return failure("User is required") unless @user

      @is_first_entry = @user.tracking_entries.none?
      @evaluation_lead = latest_evaluation_lead if @is_first_entry
      @today_entry = @user.tracking_entries.find_by(recorded_on: Date.current)

      self
    rescue StandardError => e
      @error = "Error checking tracking prefill: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end

    private

    def failure(message)
      @error = message
      self
    end

    def latest_evaluation_lead
      EvaluationLead.where(email: @user.email).order(created_at: :desc).first
    end
  end
end
