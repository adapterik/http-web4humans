require 'digest'
require_relative './EndpointHandler'
require_relative '../responses'

class ArchivedSites < EndpointHandler
    def set_page_id
        # TODO: make a more generic initialization callback for initialize...
        @archive_name = @context[:request][:arguments][0]

        possible_archive_id = @context[:request][:arguments][1]

        # Note that we allow nothing in the id part, which accomodates hitting the
        # url without a page - in which case we default to the first page.
        if possible_archive_id.nil? or possible_archive_id.length == 0
          @archive_id = 1
        elsif possible_archive_id.match?(/\d+/)
          @archive_id = possible_archive_id.to_i
        else
          @archive_id = nil
          @page_id = "#{possible_archive_id}-#{@archive_name}-archive"
        end

        puts 'HMM'
        puts @archive_name

        # trail = @context[:request][:params][:trail]
        # @trail = trail.nil? ? [] : trail.split(',')
        # puts 'NAV PATH', trail, @trail
    end

    def handle_get_about_page()
      # Here we fetch the associated item
      page, content_type = fetch_page
      
      # Create the context object, which is a merging of
      # - the site, contemnt def, menu, etc. see below
      request = {
        ip: ENV['REMOTE_ADDR'],
        referrer: ENV['HTTP_REFERER'],
        ui: ENV['HTTP_USER_AGENT']
      }
  
      # @context.merge!({
      #   site: @site,
      #   page: page,
      #   content_type: content_type,
      #   env: {
      #     request: request
      #   },
      # })

      @context.merge!({
        site: @site,
        page: page,
        content_type: content_type,
        archive: {
          name: @archive_name
        },
        env: {
          request: request
        },
      })
  
      render_template
    end

    def handle_archive_page(archive_name, archive_id)
      # page, content_type = fetch_page
      
      content_path = "#{@dir}/../../archived-sites/#{archive_name}/pages/page_#{archive_id}.body.html"
      content = load_file content_path

      # original_content_path = "#{@dir}/../../archived-sites/#{archive_name}/pages/page_#{archive_id}.html"
      # original_content = load_file original_content_path

      metadata_path = "#{@dir}/../../archived-sites/#{archive_name}/pages/page_#{archive_id}.meta.json"
      metadata = load_json metadata_path
      metadata['last_checked'] = metadata['last_fetched']
      # metadata['days_since_last_checked'] = Time.now - Time.new(metadata['last_checked'])

      # content_hash = Digest::MD5.hexdigest original_content
      # metadata['content_hash_comparison'] = content_hash == metadata['content_hash'] ? 'same' : 'different'

      # Create the context object, which is a merging of
      # - the site, contemnt def, menu, etc. see below
      request = {
        ip: ENV['REMOTE_ADDR'],
        referrer: ENV['HTTP_REFERER'],
        ui: ENV['HTTP_USER_AGENT']
      }

      page = {}

      page['title'] = "#{metadata['head']['title']} | #{@archive_name} archive #{page['title']}"

      puts 'TITLE??'
      puts metadata

      # page_path = "/archive-raw/#{archive_name}/#{archive_id}"

      # search_component = @trail.push(archive_id)

      # archive_uri = URI.build path: page_path, query: search_component

      # puts 'ARCHIVE URI'
  
      @context.merge!({
        site: @site,
        page: page,
        # content_type: content_type,
        archive: {
          name: archive_name,
          page_id: archive_id,
          raw_path: "/archive-raw/#{archive_name}/#{archive_id}",
          content: content,
          metadata: metadata
        },
        env: {
          request: request
        },
      })
  
      render_template
    end

    def handle_error(title, message)
      raise ClientError.new message
    end

    def handle_message(title, content, next_path=nil)
      page, content_type = fetch_page

      request = {
        ip: ENV['REMOTE_ADDR'],
        referrer: ENV['HTTP_REFERER'],
        ui: ENV['HTTP_USER_AGENT']
      }
      page = {
        'title' => title
      }
      @context.merge!({
        site: @site,
        page: page,
        content_type: content_type,
        env: {
          request: request
        },
        archive: {
          name: @archive_name,
          page_id: @archive_id,
          raw_path: "/archive-raw/#{@archive_name}/#{@archive_id}",
          content: '',
          metadata: {}
        },
        message: {
          'title' => title,
          'content' => content,
          'next_path' => next_path
         }
      })

      render_misc_template 'ArchiveMessage'
    end
    
    def handle_get_archive_page()
        # Load index and find archive page
        # TODO: replace csv with sqlite
        archive_index_path = "#{@dir}/../../archived-sites/#{@archive_name}/db.csv"
        archive_index = load_csv archive_index_path
        page_entry = archive_index[@archive_id-1]

        if page_entry.nil?
          raise NotFound.new "The #{@archive_name} archive page #{@archive_id} was not found"
        end

        id, parent_page_id, uri, status, *extra = page_entry

        @page_entry = {
          archive_id: id,
          parent_page_id: parent_page_id,
          uri: uri,
          status: status
        }

        case status
        when 'complete'
          handle_archive_page @archive_name, @archive_id
        when 'pending'
          handle_message 'Page in Pending State', "The requested archive page <code>#{uri}</code> is pending import"
        when 'inprogress'
          handle_message 'Page in inprogress State', "The requested archive page <code>#{uri}</code> was being imported when it was interrupted"
        when 'error'
          handle_message 'Error Fetching Page', "The requested archive page <code>#{uri}</code> threw an error during import"
        when 'external'
          handle_message 'External Page Not Supported', "The requested external page <code>#{uri}</code> is not yet supported"
        end
    end

    def handle_get()
        # If we don't have an archive page id, we show the archive's page content;
        if @archive_id.nil?
          handle_get_about_page
        else
          handle_get_archive_page
        end
    end
end