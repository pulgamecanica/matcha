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
        gender sexual_preferences
      ],
      enums: {
        gender: VALID_GENDERS,
        sexual_preferences: VALID_PREFS
      }
    )
  end

  def self.validate_update!(params)
    allowed_keys = %w[
      username first_name last_name biography
      gender sexual_preferences latitude longitude
    ]

    unknown_keys = params.keys - allowed_keys
    unless unknown_keys.empty?
      raise Errors::ValidationError.new("Unknown fields", unknown_keys)
    end

    Validator.validate!(
      params: params,
      enums: {
        gender: VALID_GENDERS,
        sexual_preferences: VALID_PREFS
      }
    )
  end
end
