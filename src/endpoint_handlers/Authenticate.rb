require_relative './EndpointHandler'

class Authenticate < EndpointHandler
  # def initialize(context, input)
  #   super(context)
  #   # if @context[:arguments].length == 0
  #   #   @page_id = 'home'
  #   # else
  #   #   @page_id = context[:arguments][0]
  #   # end
  # end

  # def include_page_content()
  #   template = ERB.new @context[:page]['content']
  #   fulfilled_content = template.result binding
  #   rendered = Kramdown::Document.new(fulfilled_content).to_html
  #   set_rendered(@context[:page_id], rendered)
  # end
  # 
  
  # def ensure_can_edit()
  #    # Ensure authenticated session that can edit.
  #    if @context[:session].nil?
  #     raise ClientErrorUnauthorized.new
  #   end
  #   if @context[:session]["can_edit"] == 0
  #     raise ClientErrorForbidden.new
  #   end
  # end

  #
  # The GET method displays the editor form
  #
  # def handle_get()
  #   ensure_can_edit

  #   # This allows the header to highlight the page being edited.
  #   edited_page_id = @context[:arguments][0]
  #   @context[:page_id] = edited_page_id
  #   @context[:page] = {
  #     'id' => edited_page_id,
  #     'title' => "Editing page #{edited_page_id}"
  #   }

  #   content = @site_db.get_content(edited_page_id)

  #   @data = {
  #     :page_id => edited_page_id,
  #     :content => content
  #   }

  #   #
  #   # 
  #   # 
  #   dir = File.dirname(File.realpath(__FILE__))
  #   path = "#{dir}/../templates/endpoints/Editor.html.erb"
  #   template = load_template(path)
  #   template.result binding
  # end
  # 
  

  def handle_post()
    # ensure_can_edit

    # edited_page_id = @context[:arguments][0]

    data = URI.decode_www_form(@input.gets).to_h

    if data.has_key? '_method'
      fake_method = data['_method']
      case fake_method.downcase
      when 'post'
        handle_signin(data)
      when 'delete'
        handle_signout(data)
      end
    else 
      handle_signin(data)
    end

  end


  def handle_signout(data)

    if @context[:session].nil?
      raise ClientError.new('Sorry, cannot logout since not logged in!')
    end

    session_id = @context[:session]["session_id"]

    @site_db.remove_session(session_id)

    expires = 1000 * 60 * 60 * 24 * 2;
    ['', 302, {
      'location' => data['return-path'],
      'Set-Cookie': "sid=#{session_id};path=/;expires=#{expires}"
    }]
  end

  def handle_signin(data)
    username = data['username']
    if username.nil?
      raise ClientError.new 'Sorry, username required'
    end

    password = data['password']
    if password.nil?
      raise ClientError.new 'Sorry, password required'
    end

    if username == 'owner'
        if password != @context[:owner_password]
          raise ClientError.new "Sorry, bad root auth"
        end
    else 
      auth = @site_db.get_user_auth(username, password)
      if auth.nil?
        raise ClientError.new 'Sorry, incorrect username and/or password'
      end
    end

    # create session
    session_id = @site_db.create_session(username)

    # set session cookie and redirect to ... home page for now.
    # two week expireation for login token...
    expires = 1000 * 60 * 60 * 24 * 2;


    # ['', 302, {'location' => "/page/#{edited_page_id}"}]
    ['', 302, {
      'location' => data['return-path'],
      'Set-Cookie': "sid=#{session_id};path=/;expires=#{expires}"
    }]
  end
end