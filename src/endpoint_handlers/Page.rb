require_relative './EndpointHandler'

class Page < EndpointHandler
  def set_page_id()
    @page_id = @context[:request][:arguments][0]
  end

  def handle_get()
    # Here we fetch the associated item
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

    render_template
  end
end