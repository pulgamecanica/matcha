require 'base64'
require 'json'
require 'openssl'

module SessionToken
  HEADER = { alg: "HS256", typ: "JWT" }.freeze
  SECRET = ENV['JWT_SECRET'] || 'development_secret'

  def self.generate(user_id)
    payload = {
      user_id: user_id,
      exp: Time.now.to_i + (60 * 60 * 92) # 92h expiry
    }

    header_b64  = Base64.urlsafe_encode64(HEADER.to_json)
    payload_b64 = Base64.urlsafe_encode64(payload.to_json)
    signature   = sign("#{header_b64}.#{payload_b64}")

    [header_b64, payload_b64, signature].join(".")
  end

  def self.decode(token)
    header_b64, payload_b64, signature = token.split(".")

    return nil unless secure_compare(signature, sign("#{header_b64}.#{payload_b64}"))

    payload = JSON.parse(Base64.urlsafe_decode64(payload_b64))
    return nil if payload["exp"] && Time.now.to_i > payload["exp"]

    payload
  rescue
    nil
  end

  def self.sign(data)
    OpenSSL::HMAC.hexdigest("SHA256", SECRET, data)
  end

  def self.secure_compare(a, b)
    return false if a.nil? || b.nil? || a.bytesize != b.bytesize

    l = a.unpack "C#{a.bytesize}"
    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end
end
