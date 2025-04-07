require_relative './validator'

module UserValidator
  def self.validate!(params)
    Validator.validate!(
      params: params,
      required: %i[
        username email password
        first_name last_name
        gender sexual_preferences
      ],
      enums: {
        gender: %w[male female other],
        sexual_preferences: %w[male female non_binary everyone]
      }
    )
  end
end
