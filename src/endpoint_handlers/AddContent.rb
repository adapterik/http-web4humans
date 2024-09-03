require 'securerandom'
require_relative './EndpointHandler'
require_relative '../responses'

class AddContent < EndpointHandler
  #
  # The GET method displays the editor form
  #
  def handle_get()
    ensure_can_edit

    # This allows the header to highlight the page being edited.
    content_type_id = @context[:arguments][0]

    # @context[:content_id] = edited_content_id
    @context[:content] = {
      'id' => '',
      'title' => "Add content item of type #{content_type_id}",
    }
    @context[:page] = {
      'title' => @context[:content]['title']
    }

    content_type = @site_db.get_content_type(content_type_id)

    # content = @site_db.get_content(edited_content_id)
    # 
    content = {
      'id' => '',
      'title' => '',
      'content' => '',
      'author' => '',
      'created' => 0,
      'last_updated' => 0
    }

    @data = {
      :content_id => '',
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

  #
  # The POST method handles the form submission.
  #
  def handle_post()
    ensure_can_edit

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']
    if fake_method.downcase != 'post'
      raise ClientError('Sorry, only "post" supported')
    end

    if form_data['id'].length == 0
      form_data['id'] = SecureRandom.uuid
    end

    @site_db.add_content(form_data)

    ['', 302, {'location' => "#{form_data['return_path_success']}"}]
  end
end