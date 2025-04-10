# frozen_string_literal: true

require_relative './validator'

module UserValidator
  VALID_GENDERS = %w[male female other].freeze
  VALID_PREFS   = %w[male female non_binary everyone].freeze

  def self.validate!(params)
    Validator.validate!(
      params: params,
      required: %i[
        username email password
        first_name last_name
      ]
    )
  end

  def self.validate_update!(params)
    allowed_keys = %w[
      username first_name last_name biography
      gender sexual_preferences latitude longitude
    ]

    unknown_keys = params.keys - allowed_keys
    raise Errors::ValidationError.new('Unknown fields', unknown_keys) unless unknown_keys.empty?

    Validator.validate!(
      params: params,
      enums: {
        gender: VALID_GENDERS,
        sexual_preferences: VALID_PREFS
      }
    )
  end
end
