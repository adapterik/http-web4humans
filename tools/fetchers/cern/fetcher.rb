require 'net/http'
require 'nokogiri'
require 'securerandom'
require 'json'
require 'sqlite3'
require 'csv'
require 'date'
require 'htmlbeautifier'
require 'digest'
require_relative 'db'

# The fetcher
# 
# Fetches the entire CERN site
# 

class NotFound < Exception
  def initialize(message=nil)
    @message = message
  end
end


def usage()
  puts 'USAGE: fetch-site URL DEST'
end

def get_paths(content, base_uri)
  base = base_uri.to_s
  content.scan(/<a[ ]+href="(.*?)"/).map do |m|
    url = m[0]
    if url.start_with? base
      url[base.length, url.length - base.length]
    end
  end
end

def get_stylesheet_urls(content)
  content.scan(/<a[ ]+href="(.*?)"/).map do |m|
    m[0]
  end
end

def get_javascript_urls(content)
  content.scan(/<img[ ]+src="(.*?)"/).map do |m|
    m[0]
  end
end

# def get_page(url)
#   response = Net::HTTP.get(URI(url))

#   response
# end

def clean_path(path)
  split_path = path.split('/').map do |element|
    element.strip
  end
  split_path.join('/')
end

class Crawler
  def initialize(root_uri, dest)
    @root_uri = root_uri
    @destination_directory = dest
    @base_url = root_uri.to_s
    @crawl_tries = 3
    @crawl_interval = 1 # seconds
    @current_depth = 0
    # @current_page_id = 0
    @log_id = 0
    @db = DB.new "#{@destination_directory}/db.csv"
    # @db.clear
    @db.save
  end

  def inc_depth()
    @current_depth += 1
  end

  def dec_depth()
    @current_depth -= 1
  end

  def normalize_path(uri, relative_path)
    base_path_list = uri.path.split('/')
    if base_path_list.length == 0
      base_path = ''
    else
      base_path = base_path_list[0, base_path_list.length - 1].join('/')
    end

    # TODO: ugh, improve.
    full_path = [base_path, relative_path].join('/').split('/')

    final_path = []

    full_path.each do |element|
      if element == '..'
        final_path.pop
        if final_path.length == 0
          # TODO: should raise here??
          error 'BAD URL', "path nav ".." pops above root: #{full_path.join('/')}"
          return nil
        end
      elsif element == '.'
        # nothing to do
      else
        final_path.push element
      end
    end

    final_path.join('/')
  end

  def is_crawled?(uri)
    

    page = @db.page_for_uri uri

    if page.nil?
      return false
    end
    
    id, parent_page_id, uri, status, *extra = page

    if status == 'pending'
      return false
    end

    return true
  end

  def log(message, log_type, also_print=false)
    @log_id += 1
    indent = '  ' * @current_depth
    log_line = "#{DateTime.now.iso8601} #{log_type} #{indent}#{message}\n"
    File.open "#{@destination_directory}/log.txt", 'a' do |file|
      file.write log_line
      puts(log_line) if also_print
    end 
  end

  def note(title, message='')
    log "#{title}: #{message}", 'note'
  end

  def warn(title, message)
    log "#{title}: #{message}", 'warn'
  end

  def error(title, message)
    log "#{title}: #{message}", 'error', true
  end

  def process_html(page_id, uri, doc)
    #
    # Extract links
    #
    doc.search('a').each do |link|
      link_href = link['href']

      #
      # The link href attribute may be missing.
      # 
      if link_href.nil?
        if link.name.nil?
          # error 'NO PATH', link_href
          warn 'NO HREF OR NAME', link_href
        end
        next
      end

      raw_uri = URI.parse(link_href)
      fetch_uri = raw_uri.clone
      fetch_uri.fragment = nil

      #
      # Handle hrefs which are just a path.
      #
      if fetch_uri.scheme.nil?
        # Just a path; we need to clean up the path and form a full uri from it.
        # Clean up the href - there may be spaces, specifically.
        path = clean_path fetch_uri.path

        if path.nil? or path.length == 0
          # this can happen if the href is just a fragment, or query
          # weird, but happens.
          # We ignore them
          if link.name.nil?
            error 'NO PATH', link_href
          end
          next
        end

        resolved_path = path.start_with?('/') ? path : normalize_path(uri, path)
          
        # happens if the normalized path is invalid.
        next if resolved_path.nil?

        # There are a bunch of bad paths with ../..
        if resolved_path.end_with? '/hypertext/WWW/NeXT/Menus.html'
          resolved_path = '/hypertext/WWW/NeXT/Menus.html'
        end

        resolved_uri = URI.join @base_url, resolved_path
      else 
        resolved_uri = fetch_uri
      end

      resolved_uri_s = resolved_uri.to_s

      if resolved_uri_s.start_with? @base_url
        if resolved_uri.path.start_with?('/hypertext/WWW/MarkUp/MarkUp.html')
          puts 'INTERNAL?'
          puts resolved_uri.to_s
          puts @db.has_uri? resolved_uri
        end
        # Some internal links are full uris.
        if @db.has_uri? resolved_uri
          link_page_id, = @db.page_for_uri resolved_uri
        else
          if resolved_uri.port.nil? or resolved_uri.port != 80
            link_page_id = @db.add_entry page_id, resolved_uri, 'external'
          else
            # some fucked up urls... or was it acceptable to use
            # ./ as the base of a path at some point?
            if resolved_uri.host.end_with? "."
              resolved_uri.host = resolved_uri.host[0..-2] 
            end
            link_page_id = @db.add_entry page_id, resolved_uri, 'pending'
          end
        end

        # Rewrite the url for the local archive url.
        # uri = URI::HTTP.build scheme: @root_uri.scheme, host: @root_uri.host, path: path
        archive_path = "/archive/cern/#{link_page_id}"
        # archive_uri = URI::HTTP.build scheme: @root_uri.scheme, host: @root_uri.host, path: archive_path
        link['original-href'] = link['href']
        link['href'] = archive_path 

        link['archive-page-id'] = link_page_id       
      elsif resolved_uri.scheme == 'file'
        # Externals may be file references, common on the cern site.
        # e.g. file://ftp.ifi.uio.no/pub/SIGhyper/1991-001
        if @db.has_uri? resolved_uri
          link_page_id, = @db.page_for_uri resolved_uri
        else
          link_page_id = @db.add_entry page_id, resolved_uri, 'file'
        end
        
        archive_path = "/archive/cern/#{link_page_id}"
        link['href'] = archive_path

        note 'FILE PATH', resolved_uri_s
      else
        # All external urls are simply recorded, for now.
        if @db.has_uri? resolved_uri
          link_page_id, = @db.page_for_uri resolved_uri
        else
          link_page_id = @db.add_entry page_id, resolved_uri, 'external'
        end

        archive_path = "/archive/cern/#{link_page_id}"
        link['href'] = archive_path

        note 'EXTERNAL URI', resolved_uri_s
      end
  
    end

    #
    # Fix html
    #
    
    # no head and body? 
    # wrap all in body, add empty head
    
    has_head = doc.search('head').length > 0
    has_body = doc.search('body').length > 0
    has_header = doc.search('header').length > 0

    if not has_head
      doc.root.prepend_child '<head></head>'
    end

    if not has_body 
      doc.root.add_child '<body></body>'
    end

    head = doc.search('head')[0]
    body = doc.search('body')[0]

    # The mysterious "heading" tag is mostly just the "head" tag; so move
    # everything to body, we'll deal with sorting out to head next.
    
    if has_header
      header = doc.search('header')[0]
      header.search('*').each do |node|
        body.add_child node
      end
      header.remove
    end

    # Now we have a head a body, although things are not sorted out yet.
    # nokogiri will not get things right on the initial parse.
    # Simplest strategy is to move everything to the body, then just head-only
    # tags to the head.
    
    head.search('*').each do |node|
      body.add_child node
    end

    body.search('title').each do |node|
      head.add_child node
    end

    body.search('meta').each do |node|
      head.add_child node
    end

    # Fix some obsolete tags...
    
    body.search('xmp').each do |node|
      pre_node, = node.add_next_sibling '<pre></pre>'
      node.search('*').each do |xmp_content_node|
        pre_node.add_child xmp_content_node
      end
    end

    # Now we extract the head, and save that to a JSON file. We only want the "body" in the 
    # file, so that we can insert it directly into the page.
    json_head = {}
    # puts 'HEAD NODE', head.search('*').keys
    head.children().each do |node|
      # body.add_child node
      # json_head[node.name] = node.text
      # puts 'HEAD NODE', node.class.name, node.name, node.content
      json_head[node.name] = node.content
    end

        
     # Add everything to the body
    #  body = Nokogiri::DocumentFragment.parse('<body>')
    #  all_nodes = doc.search('*')
    #  all_nodes.each do |node|``
    #    body.add_child node
    #  end

    # Now move 

    
    # have head and no body?
    # probably nokogiri wrapping everything in the head
    # make body 
    # move all to body
    # move title and meta back into head
    
    # have "header" obsolete tag? Move contents to head, remove it
    
    # have "nextid"? 
    # move contents into it's parent, just before nextid.
    # then remove nextid
    
    # @db.save
  end

  def handle_http(page_id, uri)
    page = nil
    tries = 0
    start_time = Time.new
  
    @db.set_entry_inprogress page_id

    (1..@crawl_tries).each do |try_count|
      begin
        tries += 1
        # page = get_page(uri)
        response = Net::HTTP.get_response(uri)

        if response.code != '200'
          error "ERROR RESPONSE", "#{uri.to_s}, #{response.code}"
          @db.set_entry_error page_id, "ERROR_RESPONSE_#{response.code}", "response code is #{response.code}"
          return
        end

        page = response.body
      rescue Exception => e # from TCPSocket::initialize
        warn 'CANNOT CONNECT (reconnecting)', e.to_s
        sleep @crawl_interval
      else
        break
      end
    end

    end_time = Time.new

    elapsed_time = end_time - start_time

    if page.nil?
      error 'BAD PAGE', uri.to_s
      @db.set_entry_error page_id, "BAD_PAGE", "after #{tries} tries"
      return
    end

    # page_name = SecureRandom.uuid
    page_name = "page_#{page_id}"
    page_path = "#{@destination_directory}/pages/#{page_name}"

    #
    # HTML FIXES
    # 
    # We must apply these to the text, afaik, because nokogiri will alter the structure
    # when it finds errors.
    #

    # I don't know how to have nokogiri accept arbitrary non-standard 
    # unclosable tags, so just search and replace the text for now.
    
    page.gsub! %r/<NEXTID [^>]*>/, ''

    # Note this should allow the begin and end tags to be separate lines.
    page.gsub! %r/<H2>(.*)<\/H3>/m, '<h2>\1</h2>'


    doc = Nokogiri::HTML(page)

    File.open "#{page_path}.html", 'w' do |file|
      file.write(page)
    end

    # update_index page_id, uri

    @db.set_entry_complete page_id, elapsed_time

    process_html page_id, uri, doc

    # Now we extract the head, and save that to a JSON file. We only want the "body" in the 
    # file, so that we can insert it directly into the page.
    metadata = {
      :id => page_id,
      :created => Time.now.utc.iso8601,
      :last_fetched => Time.now.utc.iso8601,
      :content_hash => Digest::MD5.hexdigest(page),
      :head => {}
    }
    # puts 'HEAD NODE', head.search('*').keys
    doc.search('head').children().each do |node|
      # body.add_child node
      # json_head[node.name] = node.text
      # puts 'HEAD NODE', node.class.name, node.name, node.content
      if node.name == 'text'
        next
      end
      metadata[:head][node.name] = node.content
    end

    File.open "#{page_path}.meta.json", 'w' do |file|
      # formatted = HtmlBeautifier.beautify doc.to_s
      # file.write(JSON.generate(json_head).dump())
      # JSON.dump(metadata, file)
      file.write(JSON.generate(metadata, {indent: '    ', space: ' ', object_nl: "\n", array_nl: "\n"}))
    end

    File.open "#{page_path}.body.html", 'w' do |file|
      formatted = HtmlBeautifier.beautify doc.search('body')[0].to_s
      formatted.gsub!('<body>', '<div data-element="archive-body">')
      formatted.gsub!('</body>', '</div>')
      file.write(formatted)
    end
  end

  def crawl(page_id, uri=nil)
    inc_depth
    crawl_internal page_id, uri
    dec_depth
  end
 
  def crawl_internal(page_id, uri=nil)
    # note 'CRAWL', uri.nil? ? '<none>' : uri.to_s
    # puts 'IS CRAWLED?', uri, is_crawled?(uri) 

    if uri.nil?
      uri = @root_uri
    end

    if is_crawled? uri
      # note 'skipping'
      return
    end

    # What can we fetch?
    # a page from this site
    # some resource missing from the site we have been able to find
    # elsewhere
    # some external resource no longer present at the desired location
    # be we've found and stashed away here.
    
    case uri.scheme
    when 'http'
      handle_http page_id, uri
    when 'https'
      @db.set_entry_error page_id, 'HTTPS_NOT_SUPPORTED', 'We don''t currently support https urls'
      warn 'HTTPS NOT SUPPORTED', 'We don''t currently support https urls'
    when 'file'
      @db.set_entry_error page_id, 'FILE_NOT_SUPPORTED', 'We don''t currently support file urls'
      warn 'FILE NOT SUPPORTED', 'We don''t currently support file urls'
    end
  end

  def report
    puts "DONE"
  end

  def process_pending
    done = false

    while not done 
      db = @db.read

      pending = db.select do |page_id, parent_id, uri, status, *extra|
        status == 'pending'
      end

      if pending.length == 0
        break
      end

      pending.each do |page_id, parent_page_id, uri, status, *extra|
        puts 'PENDING', page_id, uri
        # uri = URI.parse uri
        # uri = URI::HTTP.build scheme: @root_uri.scheme, host: @root_uri.host, path: path
        crawl page_id, URI.parse(uri)
      end
    end
  end

  def start
    if @db.size == 0
        if @root_uri.path == ""
          @root_uri.path = "/"
        end

        @db.add_entry 0, @root_uri, 'pending'
    end
    @db.save
    process_pending
  end
end


def main()
  # Handle arguments
  
  url_to_fetch = ARGV[0]

  destination_directory = ARGV[1]

  uri = URI.parse(url_to_fetch)

  crawler = Crawler.new uri, destination_directory
  crawler.start
  # crawler.process

  puts crawler.report
end

# def test()
#   url_to_fetch = ARGV[0]
#   destination_directory = ARGV[1]
#   db = DB.new "#{destination_directory}/db.csv"
#   db.clear
#   db.add_entry_pending 1, 'foo'
#   db.set_entry_complete 1
#   db.set_entry_error 1
#   db.set_entry_inprogress 1
# end

main()
# test()