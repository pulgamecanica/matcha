module Errors
  class ValidationError < StandardError
    def initialize(message = "Validation failed", details = nil)
      super(message)
      @details = details
    end

    attr_reader :details
  end
end
