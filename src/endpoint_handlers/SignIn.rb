require_relative './EndpointHandler'

class SignIn < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @page_id = context[:endpoint_name]
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

    render_template()
  end
end
