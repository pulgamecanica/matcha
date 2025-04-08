require "open-uri"

module ImageAnalyzer
  def self.valid_image_url?(url)
    uri = URI.parse(url)
    return false unless uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)

    response = URI.open(url)
    content_type = response.content_type
    content_type.start_with?("image/")
  rescue
    false
  end
end
