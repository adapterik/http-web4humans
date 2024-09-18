require_relative './EndpointHandler'
require_relative '../responses'

class Edit < EndpointHandler
  #
  # The GET method displays the editor form
  #
  def handle_get()
    ensure_can_edit

    page, content_type = fetch_page

    edited_content_id = @context[:request][:arguments][0]

    @context[:content_id] = edited_content_id

    content = @site_db.get_content(edited_content_id)

    # TODO: the content type info can also be returned from query above,
    content_type = @site_db.get_content_type(content['content_type'])

    page['title'] = "Editing content item #{edited_content_id}"

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

    # TODO: sort out the duplication; commonly used things required by
    # partials should be in context.

    @data = {
      :content_id => edited_content_id,
      :content => content,
      :content_type => content_type,
      :return_path_success => @context[:request][:params]['return_path_success'],
      :return_path_cancel => @context[:request][:params]['return_path_cancel']
    }

    render_template
  end

  def handle_post()
    ensure_can_edit

    edited_content_id = @context[:request][:arguments][0]

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']
    if fake_method.downcase != 'put'
      raise ClientError('Sorry, only "put" supported')
    end

    @site_db.update_content(edited_content_id, form_data)

    if form_data['apply'] == 'true'
      ['', 302, {'location' => "/edit/#{edited_content_id}?return_path_success=#{form_data['return_path_success']}&return_path_cancel=#{form_data['return_path_cancel']}"}]
    else
      ['', 302, {'location' => form_data['return_path_success']}]
    end
  end
end