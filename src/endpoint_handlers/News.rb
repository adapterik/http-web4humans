require_relative './EndpointHandler'

class News < EndpointHandler
  def handle_get()
    page, content_type = fetch_page

    #
    # The a list of articles - which is all content items of content type "article"
    #

    articles = @site_db.list_content('article', sort: ['created', 'descending'])

    article = nil

    article_id = @context[:request][:arguments][0]

    if article_id 
      article = @site_db.get_content article_id
    end

    if article_id.nil? && articles.length > 0
      article = articles[0]
      article_id = article['id']
    end

    article_content_type = nil
    if article
      article_content_type = @site_db.get_content_type(article['content_type'])
    end

    # Create the context object, which is a merging of
    # - the site, page def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }
  

    if article_id 
      page['title'] = "#{page['title']}: #{article['title']}"
    else
      page['title'] = page['title']
    end

    @content_item = {
      entry: article,
      entries: articles,
      content_type: article_content_type
    }

    @context.merge!({
      site: @site,
      page: page,
      content_type: content_type,
      env: {
        request: request
      },
    })

    render_template()
  end
end