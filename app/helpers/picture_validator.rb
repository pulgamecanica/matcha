require_relative '../lib/errors'
require_relative '../lib/image_analyzer'
require_relative './validator'

module PictureValidator
  def self.validate_url(url)
    errors = []
    errors << "url must be a valid image URL" unless ImageAnalyzer.valid_image_url?(url)
    errors
  end

  def self.validate_create!(params)
    Validator.validate!(
      params: params,
      required: [:url]
    )

    errors = validate_url(params["url"])
    if params.key?("is_profile") && ![true, false].include?(params["is_profile"])
      errors << "is_profile must be a boolean"
    end

    raise Errors::ValidationError.new("Invalid picture data", errors) unless errors.empty?
  end

  def self.validate_update!(params)
    errors = []
    if params.key?("url")
      errors += validate_url(params["url"])
    end
    if params.key?("is_profile") && ![true, false].include?(params["is_profile"])
      errors << "is_profile must be a boolean"
    end
    raise Errors::ValidationError.new("Invalid picture data", errors) unless errors.empty?
  end
end
