require_relative './EndpointHandler'

class RawArchivedSite < EndpointHandler
    def set_page_id
        archive_name = @context[:request][:arguments][0]
        @page_id = "#{archive_name}-archive"
        @archive_id = @context[:request][:arguments][1]
    end

    # def handle_get_archive_page()
    #     page, content_type = fetch_page
    
    #     # Create the context object, which is a merging of
    #     # - the site, contemnt def, menu, etc. see below
    #     request = {
    #       ip: ENV['REMOTE_ADDR'],
    #       referrer: ENV['HTTP_REFERER'],
    #       ui: ENV['HTTP_USER_AGENT']
    #     }
    
    #     @context.merge!({
    #       site: @site,
    #       page: page,
    #       content_type: content_type,
    #       env: {
    #         request: request
    #       },
    #     })
    
    #     render_template
    # end

    def handle_get()
        # page, content_type = fetch_page
        # "<p>Hi, endpoint is <code>#{@context[:request][:endpoint_name]}</code></p>" +
        # "<p>page_id is <code>#{@context[:request][:arguments]}</code></p>"

        # If we don't have an archive page id, we show the archive's page content;
        # this serves as the archive home page.
        # if @archive_id.nil?
        #     handle_get_archive_page
        # else
        #     "will get #{@archive_id}"
        # end
        # 
        
        # Get the page's file
        dir = File.dirname(File.realpath(__FILE__))
        path = "#{dir}/../../archived-sites/#{@archive_name}/pages/#{@archive_id}.html"
        content = load_file path

        content
        # 
        # Return it...
    end
end