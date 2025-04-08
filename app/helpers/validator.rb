require_relative '../lib/errors'

module Validator
  def self.validate!(params:, required: [], enums: {}, length: {})
    errors = []

    required.each do |field|
      value = params[field.to_s] || params[field.to_sym]
      if value.nil? || value.to_s.strip.empty?
        errors << "#{field} is required"
      end
    end

    enums.each do |field, valid_values|
      value = params[field.to_s] || params[field.to_sym]
      if value && !valid_values.include?(value)
        errors << "#{field} must be one of: #{valid_values.join(', ')}"
      end
    end

    length.each do |field, rules|
      value = params[field.to_s] || params[field.to_sym]
      next unless value

      if rules[:min] && value.length < rules[:min]
        errors << "#{field} must be at least #{rules[:min]} characters"
      end
      if rules[:max] && value.length > rules[:max]
        errors << "#{field} must be at most #{rules[:max]} characters"
      end
    end

    raise Errors::ValidationError.new("Validation failed", errors) unless errors.empty?
  end
end
