require "cgi"
require "json"
require 'rouge'
require 'kramdown'
require 'erb'
require 'uri'
require_relative 'SiteDB'
require_relative 'responses'

# Gets a value out of a JSON compatible structure 
def get_property(keys, context)
  if keys.length == 0 or context.nil?
    context
  else
    key = keys[0]
    rest = keys[1..]
    if context.is_a? Array and key.is_a? Integer
      get_property rest, context[key]
    elsif context.is_a? Object and key.is_a? Symbol
      get_property rest, context[key]
    else
      raise InternalError.new("Property not supported for #{key}")
    end
  end
end


class Main
  def initialize(home_dir)
    @home_dir = home_dir
    @site_db =  SiteDB.new()

    @owner_password = ENV['OWNER_PASSWORD']
  end

  def load_json(path)
    file = File.open("#{@home_dir}/data/#{path}.json")
    data = JSON.parse(file.read, symbolize_names: true)
    file.close
    data
  end

  def handle_request(env)
    # We accept any search params from the QUERY_STRING CGI key.
    query_string = env['QUERY_STRING']
    params = URI.decode_www_form(query_string).to_h

    # extract from cookies.
    # auth session from cookie
    cookies = CGI::Cookie.parse(env['HTTP_COOKIE'])
    if cookies.has_key? 'sid'
      session_id = cookies['sid']
      session = @site_db.get_session(session_id)
    else
      session = nil 
    end

    # Finally, we get the path component
    path = env['PATH_INFO']

    # If no path provided, default to the home page
    if path == '/'
      path = '/home'
    end

    uri = URI.parse(path)

    # NB things downstring expect UTF-8 - e.g. sqlite3
    path_list = String.new(uri.path, encoding: 'UTF-8').downcase.split('/').select{ |item| item.length > 0 }
    endpoint_name, *arguments = path_list

    # Find the handler for this endpoint
    handler_def = @site_db.get_endpoint(endpoint_name, arguments.length)

    if handler_def.nil?
      raise ClientError.new("ERROR - handler not found: #{endpoint_name}")
    end

    puts "" 
    puts "*******"
    puts "ENV"
    puts "*******"
    env.each_pair do |key, value| 
      puts key
      puts value
      puts '-------'
    end
    puts "*******"
    puts ""
    is_secure = env['HTTP_IS_SECURE'] == '1'

    context = {
      :method => env['REQUEST_METHOD'],
      :is_secure => is_secure,
      :host => env['SERVER_NAME'],
      :session => session,
      :path => path,
      :path_list => path_list,
      :arguments => arguments,
      :params => params,
      # need?
      :endpoint_name => endpoint_name,
      :handler_def => handler_def,
      :owner_password =>  @owner_password
    }

    endpoint_class = handler_def['class']

    require_relative "./endpoint_handlers/#{endpoint_class}"
    class_obj = Object.const_get(endpoint_class)
    class_obj.new(context, env['rack.input']).render
  end

  def call(env)
    begin
      body, status_code, header = handle_request(env)
    rescue ResponseException => response_error
      response_error.response
    else
      if header.nil?
        header = {'Content-Type' => 'text/html'}
      end 
      if status_code.nil?
        status_code = 200
      end
      # header['content-type'] = content_type
      [status_code, header, [body]]
    end
  end
end
