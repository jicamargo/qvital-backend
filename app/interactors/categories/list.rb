module Categories
  class List
    attr_reader :categories, :error

    def self.call
      new.call
    end

    def initialize
      @categories = []
      @error = nil
    end

    def call
      @categories = Category.order(:position, :name)
      self
    rescue StandardError => e
      @error = "Error listing categories: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end
  end
end

