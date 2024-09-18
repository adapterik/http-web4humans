require_relative './EndpointHandler'

class ContentItem < EndpointHandler
  def set_page_id() 
    @page_id = @context[:request][:arguments][0]
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(@context[:content_id], rendered)
  end

  def handle_get()
    # Here we fetch the associated item
    content = @site_db.get_content(@content_id)

    content_type = @site_db.get_content_type content['content_type']
    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content_id = 'not_found'
        content = @site_db.get_content(content_id)
        content[:original_content_id] = original_content_id
    end

    # We now abstract the "page" to be anything that affects the overall 
    # and generic information about the page.
    @context[:page] = {
      'title' => content['title']
    }

    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    @context.merge!({
      site: @site,
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
    path = "#{dir}/../templates/endpoints/ContentItem.html.erb"
    template = load_template(path)
    template.result binding
  end
end