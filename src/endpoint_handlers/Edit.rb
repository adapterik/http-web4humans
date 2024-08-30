require_relative './EndpointHandler'
require_relative '../responses'

class Edit < EndpointHandler
  
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
    

    # This allows the header to highlight the page being edited.
    edited_content_id = @context[:arguments][0]

    @context[:content_id] = edited_content_id


    # Here we set up a special context just for this 
    # endpoint

    content = @site_db.get_content(edited_content_id)

    # TODO: the content type info can also be returned from query above,
    content_type = @site_db.get_content_type(content['content_type'])

    page = {
      'title' => content['title']
    }

    @context[:page] = page

    # Just to please the partials.
    @context[:content] = {
      'id' => edited_content_id,
      'title' => "Editing content item #{edited_content_id}"
    }

    # TODO: sort out the duplication; commonly used things required by
    # partials should be in context.

    @data = {
      :content_id => edited_content_id,
      :content => content,
      :content_type => content_type,
      :return_path_success => @context[:params]['return_path_success'],
      :return_path_cancel => @context[:params]['return_path_cancel']
    }

    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../templates/endpoints/Edit.html.erb"
    template = load_template(path)
    template.result binding
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