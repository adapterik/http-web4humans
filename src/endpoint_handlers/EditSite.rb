require_relative './EndpointHandler'
require_relative '../responses'

class EditSite < EndpointHandler

  def get_field(data, field_path)
    for path_element in field_path
      return nil if data.nil?
      return nil if not data.has_key? path_element

      data = data[path_element]
    end
    data
  end

  #
  # The GET method displays the editor form
  #
  def handle_get()
    ensure_can_edit

    page, content_type = fetch_page

    # This allows the header to highlight the page being edited.
    edited_site_id = @context[:request][:arguments][0]

    @context[:site_id] = edited_site_id

    # Here we set up a special context just for this 
    # endpoint

    site = nil
    if not edited_site_id.nil?
      site = @site_db.get_site(edited_site_id)
    end

    # TODO: the content type info can also be returned from query above,
    # content_type = @site_db.get_content_type(content['content_type'])

    page['title'] = "Editing site #{edited_site_id}"

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

    @data = {
      :site_id => edited_site_id,
      :site => site,
      :return_path_success => @context[:request][:params]['return_path_success'],
      :return_path_cancel => @context[:request][:params]['return_path_cancel']
    }

    render_template
  end

  def handle_post()
    ensure_can_edit

    site_id = @context[:request][:arguments][0]

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']

    case fake_method.downcase
    when 'post'
      @site_db.add_site(form_data)
    when 'put'
      @site_db.update_site(site_id, form_data)
    else
      raise ClientError('Sorry, only "put" and "post" supported')
    end

    # @site_db.update_content(edited_content_id, form_data)

    if form_data['apply'] == 'true'
      ['', 302, {'location' => "/edit-site/#{site_id}?return_path_success=#{form_data['return_path_success']}&return_path_cancel=#{form_data['return_path_cancel']}"}]
    else
      ['', 302, {'location' => form_data['return_path_success']}]
    end
  end
end