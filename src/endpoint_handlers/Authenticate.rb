require_relative './EndpointHandler'

class Authenticate < EndpointHandler
  def handle_post()
    # ensure_can_edit

    # edited_page_id = @context[:request][:arguments][0]

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

    if not @session.is_authenticated?
      raise ClientError.new('Sorry, cannot logout since not logged in!')
    end

    session_id = @session.session_id

    @site_db.remove_session(session_id)

    expires = 1000 * 60 * 60 * 24 * 2;
    ['', 302, {
      'location' => data['return-path'],
      'Set-Cookie': "sid=#{session_id};path=/;expires=#{expires};secure"
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
        if password != @context[:app][:owner_password]
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

    ['', 302, {
      'location' => data['return-path'],
      'Set-Cookie': "sid=#{session_id};path=/;expires=#{expires};secure"
    }]
  end
end