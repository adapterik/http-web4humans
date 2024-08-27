require_relative './EndpointHandler'

class Page < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @content_id = context[:arguments][0]
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = Kramdown::Document.new(fulfilled_content, :input => 'GFM', :syntax_highlighter => 'rouge').to_html
    set_rendered(@context[:content_id], rendered)
  end

  def handle_get()
    # Here we fetch the associated item
    content = @site_db.get_content(@content_id)

    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content_id = 'not_found'
        content = @site_db.get_content(content_id)
        content[:original_content_id] = original_content_id
    end

    content_type = @site_db.get_content_type content['content_type']
    

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
      content_id: @content_id,
      content: content,
      content_type: content_type,
      env: {
        request: request
      },
    })

    dir = File.dirname(File.realpath(__FILE__))
    # class_name = content['content_type'].capitalize
    # path = "#{dir}/../templates/endpoints/#{class_name}.html.erb"
    path = "#{dir}/../templates/endpoints/Page.html.erb"
    template = load_template(path)
    template.result binding
  end
end