require_relative './EndpointHandler'

class News < EndpointHandler
  def initialize(context, input)
    super(context, input)
    # In this case, the page content is the same as the endpoint
    @content_id = @context[:endpoint_name]

    # Note that in the base case of going to the news home page, this 
    # is going to be nil. In that case, later we will pluck off the most
    # recent news item, if any.
    @article_id = context[:arguments][0]
  end

  #
  # There is still page content, even though we are not using the Page 
  # renderer.
  #
  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(@context[:content_id], rendered)
  end

  def handle_get()
    #
    # Here we fetch the what should be the page content for this endpoint.
    # Yes, we are punning the endpont to the page id, but it works!
    #
    content = @site_db.get_content(@content_id)
  
    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content_id = 'not_found'
        content = @site_db.get_content(content_id)
        content[:original_content_id] = original_content_id
    end

    content_type = @site_db.get_content_type content['content_type']

    #
    # The a list of articles - which is all content items of content type "article"
    #

    articles = @site_db.list_content('article', sort: ['created', 'descending'])

    article = nil

    if @article_id 
      article = @site_db.get_content @article_id
    end

    if @article_id.nil? && articles.length > 0
      article = articles[0]
      @article_id = article['id']
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

    page = {}

    if @article_id 
      page['title'] = "#{content['title']}: #{article['title']}"
    else
      page['title'] = content['title']
    end

    data = {
      article: article,
      articles: articles,
      content_type: article_content_type
    }

    @context.merge!({
      site: @site,
      page: page,
      content_id: @content_id,
      content: content,
      content_type: content_type,
      data: data, 
      env: {
        request: request
      },
    })

    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../templates/endpoints/News.html.erb"
    template = load_template(path)
    template.result binding
  end
end