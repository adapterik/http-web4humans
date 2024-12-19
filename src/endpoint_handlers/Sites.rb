require_relative './EndpointHandler'

class Sites < EndpointHandler
  def handle_get()
    page, content_type = fetch_page

    #
    # The a list of articles - which is all content items of content type "article"
    #

    sort = nil
    if @context[:request][:params]['sort_field'] 
      # TODO: project with a hash map.
      sort = [@context[:request][:params]['sort_field'], @context[:request][:params]['sort_direction']]
    end

    search = @context[:request][:params]['search']

    sites = @site_db.list_sites(sort: sort, search: search)

    using_default_site = false
    site_id = @context[:request][:arguments][0]
    if site_id 
      selected_site = @site_db.get_site(site_id)
      # sites = sites.filter do |entry|
      #   entry['id'] != site_id
      # end
    else
      if sites.length > 0 
        selected_site = sites[0]
        using_default_site = true
      else
        selected_site = nil
      end
    end
   
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
      using_default_site: using_default_site,
      env: {
        request: request
      },
    })

    render_template
  end
end