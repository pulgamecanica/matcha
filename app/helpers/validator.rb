# frozen_string_literal: true

require_relative '../lib/errors'

module Validator
  def self.validate!(params:, required: [], enums: {}, length: {})
    errors = []

    required.each do |field|
      value = params[field.to_s] || params[field.to_sym]
      errors << "#{field} is required" if value.nil? || value.to_s.strip.empty?
    end

    enums.each do |field, valid_values|
      value = params[field.to_s] || params[field.to_sym]
      errors << "#{field} must be one of: #{valid_values.join(', ')}" if value && !valid_values.include?(value)
    end

    length.each do |field, rules|
      value = params[field.to_s] || params[field.to_sym]
      next unless value

      errors << "#{field} must be at least #{rules[:min]} characters" if rules[:min] && value.length < rules[:min]
      errors << "#{field} must be at most #{rules[:max]} characters" if rules[:max] && value.length > rules[:max]
    end

    raise Errors::ValidationError.new('Validation failed', errors) unless errors.empty?
  end
end
