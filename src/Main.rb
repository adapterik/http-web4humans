require "cgi"
require "json"
require 'erb'
require 'uri'
require_relative 'SiteDB'
require_relative 'responses'
require_relative 'Session'

class Main
  def initialize(home_dir)
    # The root of the web app.
    @home_dir = home_dir

    # The site database
    @site_db =  SiteDB.new()

    # The core authentication is the site owner, which is built
    # into the site database, although the password is dynamically
    # set.
    @owner_password = ENV['OWNER_PASSWORD']
  end

  def handle_request(env)
    # We accept any search params from the QUERY_STRING CGI key, which are
    # known as "params"
    query_string = env['QUERY_STRING']
    params = URI.decode_www_form(query_string).to_h

    # Extract the auth session from the cookie, and 
    # evaluate
    # auth session from cookie
    cookies = CGI::Cookie.parse(env['HTTP_COOKIE'])
    session_id = cookies['sid'][0]
    session = Session.new(session_id)

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
    
    is_secure = env['rack.url_scheme'] == 'https'

    # The context structure is the core of sharing information from the 
    # web app into templates.
    # Here we set the top level app context - capturing facts about the 
    # web app itself. 
    # The endpoint handler will receive this, and then augment it.
    # TODO: Perhaps we should partition the context based on who or
    # which phase is adding the context.
    # context = {
    #   :method => env['REQUEST_METHOD'],
    #   :is_secure => is_secure,
    #   :host => env['SERVER_NAME'],
    #   :session => session,
    #   :path => path,
    #   :path_list => path_list,
    #   :arguments => arguments,
    #   :params => params,
    #   # need?
    #   :endpoint_name => endpoint_name,
    #   :handler_def => handler_def,
    #   :owner_password =>  @owner_password
    # }

    context = {
      :app => {
        :owner_password =>  @owner_password
      },
      :request => {
        :method => env['REQUEST_METHOD'],
        :is_secure => is_secure,
        :host => env['SERVER_NAME'],
        :path => path,
        :path_list => path_list,
        :arguments => arguments,
        :params => params,
        :endpoint_name => endpoint_name,
      }
    }

    # This is how we dynamically create endpoint handler instances.
    # We get the class name from the endpoint record. The class name
    # forms the base of the dependency filename, and also the class name.

    endpoint_class = handler_def['class']
    require_relative "./endpoint_handlers/#{endpoint_class}"
    class_obj = Object.const_get(endpoint_class)
    class_obj.new(context, session, env['rack.input']).render
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
