require 'securerandom'
require_relative './EndpointHandler'

class AddContent < EndpointHandler
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
    content_type_id = @context[:arguments][0]

    return_path = @context[:params]['return_path']

    # @context[:content_id] = edited_content_id
    @context[:content] = {
      'id' => '',
      'title' => "Add content item of type #{content_type_id}",
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
      :return_path => return_path
    }

    #
    # 
    # 
    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../templates/endpoints/Editor.html.erb"
    template = load_template(path)
    template.result binding
  end

  def handle_post()
    ensure_can_edit

    # edited_content_id = @context[:arguments][0]

    data = URI.decode_www_form(@input.gets).to_h

    # content_id = data['id']

    # TODO: validate all data!
    # 
    
    if data['id'].length == 0
      data['id'] = SecureRandom.uuid
    end

    @site_db.add_content(data)

    # content = @site_db.get_content(data['id'])

    # ['', 302, {'location' => "/#{content['content_type']}/#{content['id']}"}]
    ['', 302, {'location' => "#{data['return_path']}"}]
  end
end