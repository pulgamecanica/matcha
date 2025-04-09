class CORS
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type, If-Modified-Since'

    [status, headers, body]
  end
end
