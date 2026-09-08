module EvaluationLeads
  class Create
    attr_reader :lead, :error, :errors

    def self.call(params:)
      new(params: params).call
    end

    def initialize(params:)
      @params = params || {}
      @lead = nil
      @error = nil
      @errors = {}
    end

    def call
      @lead = EvaluationLead.new(lead_attributes)

      unless @lead.save
        @errors = @lead.errors.to_hash
      end

      self
    rescue StandardError => e
      @error = "Error creating evaluation lead: #{e.message}"
      self
    end

    def success?
      @error.nil? && @lead&.persisted?
    end

    private

    def lead_attributes
      @params.slice(:email, :age, :sex, :weight_kg, :height_cm, :waist_cm, :activity_level, :goal, :emotional_state)
    end
  end
end
