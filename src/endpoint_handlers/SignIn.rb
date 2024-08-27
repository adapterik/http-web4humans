require_relative './EndpointHandler'

class SignIn < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @content_id = context[:endpoint_name]
  end

  def include_part(part_content_id)
    part = @site_db.get_content(part_content_id)

    template = ERB.new part['content']
    fulfilled_content = template.result binding
    rendered = Kramdown::Document.new(fulfilled_content).to_html
    set_rendered(part_content_id, rendered)
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = Kramdown::Document.new(fulfilled_content, :input => 'GFM', :syntax_highlighter => 'rouge').to_html
    set_rendered(@context[:content_id], rendered)
  end

  def handle_get()
    content = @site_db.get_content(@content_id)

    template_name = 'SignIn'
  
    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content_id = 'not_found'
        content = @site_db.get_content(content_id)
        content[:original_content_id] = original_content_id
        template_name = 'Page'
    end
    
    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }


    page = {
      'title' => content['title']
    }

    @context.merge!({
      site: @site,
      page: page,
      content: content,
      env: {
        request: request
      },
    })

    dir = File.dirname(File.realpath(__FILE__))
    # class_name = content['content_type'].capitalize
    path = "#{dir}/../templates/endpoints/#{template_name}.html.erb"
    template = load_template(path)
    template.result binding
  end
end
