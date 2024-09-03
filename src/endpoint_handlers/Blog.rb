require_relative './EndpointHandler'

class Blog < EndpointHandler
  def initialize(context, input)
    super(context, input)
    # In this case, the page content is the same as the endpoint
    @page_id = @context[:endpoint_name]

    # Note that in the base case of going to the news home page, this 
    # is going to be nil. In that case, later we will pluck off the most
    # recent news item, if any.
    @blog_entry_id = context[:arguments][0]

    @content_item = nil
  end

  def handle_get()
    page, content_type = fetch_page

    #
    # The a list of blog items - which is all content items of content type "blog"
    #
    blog_entries = @site_db.list_content('blog', sort: ['created', 'descending'])

    blog_entry = nil

    if @blog_entry_id 
      blog_entry = @site_db.get_content @blog_entry_id
    end

    if @blog_entry_id.nil? && blog_entries.length > 0
      blog_entry = blog_entries[0]
      @blog_entry_id = blog_entry['id']
    end

    if blog_entry 
      blog_content_type = @site_db.get_content_type('blog')
    end

    @content_item = {
      entries: blog_entries,
      entry: blog_entry,
      content_type: blog_content_type,
    }

    # Create the context object, which is a merging of
    # - the site, page def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    if @blog_entry_id 
      page['title'] = "#{page['title']}: #{blog_entry['title']}"
    else
      page['title'] = page['title']
    end

    @context.merge!({
      site: @site,
      page: page,
      content_type: content_type,
      env: {
        request: request
      },
    })

    render_template
  end
end