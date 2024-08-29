require_relative './EndpointHandler'

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

    return_path = @context[:params]['return_path']

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
      :return_path => return_path
    }

    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../templates/endpoints/Edit.html.erb"
    template = load_template(path)
    template.result binding
  end

  def handle_post()
    ensure_can_edit

    edited_content_id = @context[:arguments][0]

    data = URI.decode_www_form(@input.gets).to_h

    # TODO: validate all data!

    @site_db.update_content(edited_content_id, data)

    # content = @site_db.get_content(edited_content_id)

    # ['', 302, {'location' => "/#{content['content_type']}/#{edited_content_id}"}]
    ['', 302, {'location' => data['return_path']}]
  end
end