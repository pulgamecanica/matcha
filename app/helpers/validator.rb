require_relative '../lib/errors'

module Validator
  def self.validate!(params:, required: [], enums: {})
    errors = []

    # Check required fields
    required.each do |field|
      value = params[field.to_s] || params[field.to_sym]
      if value.nil? || value.to_s.strip.empty?
        errors << "#{field} is required"
      end
    end

    # Check enum values
    enums.each do |field, valid_values|
      value = params[field.to_s] || params[field.to_sym]
      if value && !valid_values.include?(value)
        errors << "#{field} must be one of: #{valid_values.join(', ')}"
      end
    end

    raise Errors::ValidationError.new("Validation failed", errors) unless errors.empty?
  end
end
