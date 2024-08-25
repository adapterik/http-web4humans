require_relative './EndpointHandler'

class Home < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @content_id = 'home'
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = Kramdown::Document.new(fulfilled_content).to_html
    set_rendered(@context[:content_id], rendered)
  end

  def render_markdown(content)
    Kramdown::Document.new(content).to_html
  end

  def render_epoch_time(time)
    Time.at(time).strftime('%Y-%m-%d at %H:%M')
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

    # Now get the summaries...
    
    latest_blog_entry = @site_db.list_content 'blog', sort: ['created', 'descending'], limit: 1

    latest_news = @site_db.list_content 'article', sort: ['created', 'descending'], limit: 1

    favorite_sites = @site_db.get_sites sort: ['added', 'descending']

    @data = {
      latest_blog_entry: latest_blog_entry[0],
      latest_news: latest_news[0],
      favorite_sites: favorite_sites
    }

    dir = File.dirname(File.realpath(__FILE__))
    # class_name = content['content_type'].capitalize
    # path = "#{dir}/../templates/endpoints/#{class_name}.html.erb"
    path = "#{dir}/../templates/endpoints/Home.html.erb"
    template = load_template(path)
    template.result binding
  end
end