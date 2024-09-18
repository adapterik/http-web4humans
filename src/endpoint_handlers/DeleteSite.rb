require_relative './EndpointHandler'

class DeleteSite < EndpointHandler 
  
  #
  # The GET method displays the deletion form
  #
  def handle_get()
    ensure_can_edit

    page, content_type = fetch_page

    # This allows the header to highlight the page being edited.
    site_id_to_delete = @context[:request][:arguments][0]
    site_to_delete = @site_db.get_site(site_id_to_delete)

    # page['title'] = "Deleting #{content_to_delete_content_type['noun']} \"#{content_to_delete['title']}\""

    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    @context.merge!({
      site: @site,
      page: page,
      content_type: content_type,
      env: {
        request: request
      },
    })

    return_path_success = @context[:request][:params]['return_path_success']
    return_path_cancel = @context[:request][:params]['return_path_cancel']

    @data = {
      :site_id => site_id_to_delete,
      :site => site_to_delete,
      :return_path_success => return_path_success,
      :return_path_cancel => return_path_cancel
    }

    render_template
  end

  def handle_delete(form_data) 
    ensure_can_edit
    site_id_to_delete = @context[:request][:arguments][0]

     @site_db.delete_site(site_id_to_delete)
     
     # LEFT OFF HERE
     # let us have a system for response content for "action urls".
     # The idea is that an action should have an acknowledgement, with 
     # one or more links or buttons to guide the user onwards.
     # We _can_ also use a 302, as we have been, but it is rather abrupt if the user 
     # is unaware of what is expected to happen.
     
     

     ['', 302, {'location' => form_data['return_path_success']}]
  end

  def handle_post()
    ensure_can_edit

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']
    case fake_method.downcase
      when 'delete'
        handle_delete(form_data)
      else 
        raise ClientError('Sorry, only "delete" supported')
    end
  end

end