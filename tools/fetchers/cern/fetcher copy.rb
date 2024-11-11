require 'net/http'
require 'nokogiri'
require 'securerandom'
require 'json'
require 'sqlite3'
require 'csv'
require 'date'

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

def get_external_urls(content, base_uri)
  base = base_uri.to_s
  content.scan(/<a[ ]+href="(.*?)"/).map do |m|
    url = m[0]
    if not url.start_with? base
      url
    end
  end
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
  # path_list[0, path_list.length - 1].unshift('').join('/')
end

def path_directory(path)
  # Remove prefix or suffix spaces
  path_list = path.split('/').map do |element|
    element.strip
  end
  
  # Remove empty path segments
  path_list = path_list.filter do |element|
    element.length > 0
  end

  # path_list[0, path_list.length - 1].unshift('').join('/')
  if path_list.length == 0
    '/'
  else
    path_list[0, path_list.length - 1].unshift('').join('/')
  end
end

# class Index
#   def initialize(path)
#     @path = path

#     dir = File.dirname(File.realpath(__FILE__))
#     path = "#{dir}/../data/site.sqlite3"
#     @path = path
#     @db = open_db()

#     load_and_check()
#   end

#   def load_and_check()
#     # Loads the index file ... if it exists, simply ensure it is
#     # in the proper form; if not, create the basic template and save it
    
#     File.open "#{@path}/index.json", 'rw' do |file|
#       index = JSON.load_file(file)
#       index[html:] = data
#       file.write(index.dump)
#     end
#   end

#   def update(section, data)
#     # TODO: Eventually we'll fix this by using sqlite 3...
#     File.open "#{@path}/index.json", 'rw' do |file|
#       index = JSON.load_file(file)
#       index[html:] = data
#       file.write(index.dump)
#     end
#   end
# end

class Crawler
  def initialize(root_uri, dest)
    @root_uri = root_uri
    @destination_directory = dest
    @base_url = root_uri.to_s
    # @base_path = @root_uri.path.length > 0 ? path_directory(@root_uri.path) : '/'
    @base_path = path_directory(@root_uri.path)
    @crawl_tries = 3
    @crawl_interval = 1 # seconds
    @crawled = {}
    @current_depth = 0
    @page_id = 0
    @log_id = 0
  end

  def inc_depth()
    @current_depth += 1
  end

  def dec_depth()
    @current_depth -= 1
  end

  def get_page(uri)
    response = Net::HTTP.get_response(uri)
    # if response.code == '404'
    #   # try to get it from the missing resources.
    #   # for now, the entire path for the missing resource must match the path
    #   # within data/missing-resources.
    #   resource_path = File.join(@base_path, uri.path)
    #   if File.exist? resource_path
    #     puts "MISSING RESOURCE FOUND!"
    #     puts resource_path
    #   end
    if response.code != '200'
      error "NOT FOUND", uri
      log response.code
      # raise NotFound.new 
      return nil
    end
    response.body
  end

  def is_crawled?(uri)
    @crawled.has_key? uri.to_s
  end

  def log(message, log_type, also_print=false)
    @log_id += 1
    indent = '  ' * @current_depth
    log_line = "#{DateTime.now.iso8601} #{log_type} #{indent}#{message}\n"
    File.open "#{@destination_directory}/log.txt\n", 'a' do |file|
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

  def next_page_id()
    @page_id += 1
  end

  def update_index(page_id, uri)
    output_string = CSV.generate do |csv|
      csv << [page_id, uri.to_s]
    end

    # puts 'CSV'
    # puts output_string
    # puts "#{@destination_directory}/index.csv"

    File.open "#{@destination_directory}/index.csv", 'a' do |file|
      file.write output_string
    end
  end

  def db_create()
    File.open "#{@destination_directory}/db.csv", 'a' do |file|
      file.write ''
    end
  end

  def db_read()
    CSV.read "#{@destination_directory}/db.csv"
  end

  def db_add_entry(page_id, path, status)
    output_string = CSV.generate do |csv|
      csv << [page_id, path, status]
    end

    File.open "#{@destination_directory}/db.csv", 'a' do |file|
      file.write output_string
    end
  end

  def db_add_pending_entry(page_id, path)
    db_add_entry page_id, path, 'pending'
  end

  def db_set_entry_status(page_id, new_status)
    db = db_read
    output_string = CSV.generate do |csv|
      db.each do |id, path, status|
        if id = page_id
          status = new_status
        end
        csv << [id, path, status]
      end
    end
   
    File.open "#{@destination_directory}/db.csv", 'a' do |file|
      file.write output_string
    end
  end

  def db_set_entry_error(page_id)
    db_set_entry_status page_id, 'error'
  end

  def db_set_entry_complete(page_id)
    db_set_entry_status page_id, 'complete'
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
          error 'BAD URL', 'path nav ".." pops above root'
          log relative_path
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

  def process_html(uri, doc)
    doc.search('a').each do |link|
      link_href = link['href']
      # Local url may be complete, and start with the base_url
      if link_href.nil?
        if link.name.nil?
          # error 'NO PATH', link_href
          warn 'NO HREF OR NAME', link_href
        end
      elsif link_href.start_with? @base_url
        next_uri = URI.parse(link_href)
        # some fucked up urls... or was it acceptable to use
        # ./ as the base of a path at some point?
        if next_uri.host.end_with? "."
          next_uri.host = next_uri.host[0..-2] 
        end
        crawl next_uri
      # Otherwise local url may just be a path
      elsif not link_href.start_with? 'http'
        # Clean up the href - there may be spaces, specifically.
        path = clean_path link_href

        href_uri = URI.parse(path)

        if href_uri.path.nil? or href_uri.path.length == 0
          # this can happen if the href is just a fragment, or query
          # weird, but happens.
          if link.name.nil?
            error 'NO PATH', link_href
          end
          next
        end

        resolved_path = if href_uri.path.start_with? '/'
          # If an absolute path, just use it.
          path
        else 
          # Otherwise, seek to normalize the path
          normalize_path(uri, href_uri.path)
        end

        if resolved_path.nil?
          # happens if the normalized path is invalid.
          next
        end

        # There are a bunch of bad paths with ../..
        if resolved_path.end_with? '/hypertext/WWW/NeXT/Menus.html'
          resolved_path = '/hypertext/WWW/NeXT/Menus.html'
        end

        # Get a generic uri based on the href path
        # note 'PARSE', resolved_path
        temp_uri = URI.parse resolved_path

        # add the root information so it is a usable http url
        # local_uri.scheme = @root_uri.scheme
        # local_uri.host = @root_uri.host
        local_uri = URI::HTTP.build scheme: uri.scheme, host: uri.host, path: temp_uri.path, fragment: temp_uri.fragment, query: temp_uri.query

        # local_uri = URI::HTTP.build scheme: @root_uri.scheme, host: @root_uri.host, path: resolved_path
        # log local_uri.to_s
        crawl local_uri
      elsif not link_href.start_with? 'file:'
        # Externals may be file references, common on the cern site.
        # e.g. file://ftp.ifi.uio.no/pub/SIGhyper/1991-001
        external_uri = URI.parse link_href
        # external_path = external_uri.path
        note 'EXTERNAL PATH', external_uri.to_s
        # puts 'EXTERNAL PATH'
        # puts external_uri
        # puts external_path
      else
        note '(external)'
      end
  
    end
  end

  def handle_http(uri)
    page = nil

    next_page_id

    db_add_pending_entry @page_id, uri.path

    (1..@crawl_tries).each do |try_count|
      begin
        page = get_page(uri)
      rescue Exception => e # from TCPSocket::initialize
        warn 'CANNOT CONNECT (reconnecting)', e.to_s
        sleep @crawl_interval
      else
        break
      end
    end

    if page.nil?
      error 'BAD PAGE', uri.to_s
      db_set_entry_error @page_id
      return
    end

    # page_name = SecureRandom.uuid
    page_name = "page_#{@page_id}"
    page_path = "#{@destination_directory}/pages/#{page_name}"

    doc = Nokogiri::HTML(page)


    File.open "#{page_path}.html", 'w' do |file|
      file.write(page)
    end

    File.open "#{page_path}.parsed.html", 'w' do |file|
      file.write(doc.to_s)
    end
    
    update_index @page_id, uri

    db_set_entry_complete @page_id

    @crawled[uri.to_s] = {
      uri: uri,
      size: page.length,
      name: page_name,
      path: page_path
    }

    process_html uri, doc
  end

  def crawl(uri=nil)
    inc_depth
    crawl uri
    dec_depth
  end

  def crawl_internal(uri=nil)

    note 'CRAWL', uri.nil? ? '<none>' : uri.to_s 

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
      handle_http uri
    when 'https'
      warn 'HTTPS NOT SUPPORTED', 'We don''t currently support https urls'
    when 'file'
      warn 'FILE NOT SUPPORTED', 'We don''t currently support file urls'
    end
  end

  def report
    puts "Crawled: #{@crawled.length}"
  end
end


def main()
  # Handle arguments
  
  url_to_fetch = ARGV[0]

  destination_directory = ARGV[1]

  uri = URI.parse(url_to_fetch)

  db_create

  crawler = Crawler.new uri, destination_directory
  crawler.crawl

  puts crawler.report
end

main()