require_relative './validator'

module LikeValidator
  def self.validate!(params)
    Validator.validate!(
      params: params,
      required: [:username]
    )
  end
end
