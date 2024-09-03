require_relative './EndpointHandler'

class Sites < EndpointHandler
  def initialize(context, input)
    super(context, input)
    # In this case, the page content is the same as the endpoint
    @page_id = @context[:endpoint_name]

    # Note that in the base case of going to the news home page, this 
    # is going to be nil. In that case, later we will pluck off the most
    # recent news item, if any.
    @site_id = context[:arguments][0]
  end


  def handle_get()
    page, content_type = fetch_page

    #
    # The a list of articles - which is all content items of content type "article"
    #

    sort = nil
    if @context[:params]['sort_field'] 
      # TODO: project with a hash map.
      sort = [@context[:params]['sort_field'], @context[:params]['sort_direction']]
    end

    search = @context[:params]['search']

    sites = @site_db.list_sites(sort: sort, search: search)

    selected_site = nil


    # Create the context object, which is a merging of
    # - the site, page def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    if selected_site 
      page['title'] = "#{page['title']}: #{selected_site['title']}"
    else
      page['title'] = page['title']
    end

    @context.merge!({
      site: @site,
      page: page,
      content_type: content_type,
      sites: sites,
      selected_site: selected_site,
      env: {
        request: request
      },
    })

    render_template
  end
end