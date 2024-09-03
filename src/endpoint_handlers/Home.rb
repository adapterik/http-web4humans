require_relative './EndpointHandler'

class Home < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @page_id = 'home'
  end

  def render_epoch_time(time)
    Time.at(time).strftime('%Y-%m-%d at %H:%M')
  end

  def handle_get()
    page, content_type = fetch_page

    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
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

    # Now get the summaries...
    
    latest_blog_entries = @site_db.list_content 'blog', sort: ['created', 'descending'], limit: 5

    latest_news = @site_db.list_content 'article', sort: ['created', 'descending'], limit: 5

    favorite_sites = @site_db.get_sites sort: ['added', 'descending']

    @data = {
      latest_blog_entries: latest_blog_entries,
      latest_news: latest_news,
      favorite_sites: favorite_sites
    }

    render_template()
  end
end