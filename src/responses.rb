class ResponseException < Exception
  STATUS_CODE = nil
  CANONICAL_NAME = nil

  def initialize(message=nil)
    @message = message
  end

  def response
    [self.class::STATUS_CODE, { 'Content-Type' => "text/plain" }, [
      "#{self.class::CANONICAL_NAME}: #{@message}"
    ]]
  end
end

class ClientError < ResponseException
  STATUS_CODE = 400
  CANONICAL_NAME = "Bad Request"
end

class ClientErrorUnauthorized < ResponseException
  STATUS_CODE = 401
  CANONICAL_NAME = "Unauthorized"
end

class ClientErrorForbidden < ResponseException
  STATUS_CODE = 403
  CANONICAL_NAME = "Forbidden"
end

class ClientErrorImATeapot < ResponseException
  STATUS_CODE = 418
  CANONICAL_NAME = "I'm a Teapot"
end

class NotFound < ClientError
  STATUS_CODE = 404
  CANONICAL_NAME = "Not Found"
end

class ClientErrorMethodNotAllowed < ClientError
  STATUS_CODE = 405
  CANONICAL_NAME = "Method Not Allowed"
end

class InternalError < ResponseException
  STATUS_CODE = 500
  CANONICAL_NAME = "Internal Server Error"
end