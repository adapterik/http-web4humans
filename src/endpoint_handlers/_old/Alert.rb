require_relative './EndpointHandler'

class Alert < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @alert_id = @context[:request][:arguments][0]
  end

  def fetch_alert() 
    alert = @site_db.get_content(@alert_id)

    if alert.nil?
      raise NotFound.new
    end

    content_type = @site_db.get_content_type alert['content_type']

    return alert, content_type
  end

  def handle_get()
    # Here we fetch the associated item
    alert, content_type = fetch_alert
    
    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    page = {
      'title' => alert['title']
    }

    # Maybe buttons?

    @context.merge!({
      site: @site, 
      page: page,
      alert: alert,
      content_type: content_type,
      env: {
        request: request
      },
    })

    render_template()
  end
end