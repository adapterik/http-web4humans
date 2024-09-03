require_relative './EndpointHandler'
require_relative '../responses'

class Edit < EndpointHandler

  def initialize(context, input)
    super(context, input)
    # For the generic "news" page content
    @page_id = @context[:endpoint_name]
  end
  
  def ensure_can_edit()
     # Ensure authenticated session that can edit.
     if @context[:session].nil?
      raise ClientErrorUnauthorized.new
    end
    if @context[:session]["can_edit"] == 0
      raise ClientErrorForbidden.new
    end
  end

  #
  # The GET method displays the editor form
  #
  def handle_get()
    ensure_can_edit

    page, content_type = fetch_page

    # This allows the header to highlight the page being edited.
    edited_content_id = @context[:arguments][0]

    @context[:content_id] = edited_content_id


    # Here we set up a special context just for this 
    # endpoint

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
      :return_path_success => @context[:params]['return_path_success'],
      :return_path_cancel => @context[:params]['return_path_cancel']
    }

    render_template
  end

  def handle_post()
    ensure_can_edit

    edited_content_id = @context[:arguments][0]

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']
    if fake_method.downcase != 'put'
      raise ClientError('Sorry, only "put" supported')
    end

    @site_db.update_content(edited_content_id, form_data)

    ['', 302, {'location' => form_data['return_path_success']}]
  end
end