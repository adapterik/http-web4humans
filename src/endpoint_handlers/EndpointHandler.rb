require 'erb' 
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require_relative '../SiteDB'
require_relative '../responses'

include ERB::Util

class MyRender < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
end

class EndpointHandler
  @@file_cache = {}
  @@template_cache = {}
  @@rendered_cache = {}

  def initialize(context, input)
    @context = context
    @input = input

    @header = {}
    @data = {}
    @site = {}
    @site_db =  SiteDB.new()
    @markdown = Redcarpet::Markdown.new(MyRender, authlink: false, tables: true, fenced_code_blocks: true)
  end

  #
  # formatters
  # 

  def format_timestamp(time)
    return '' if time.nil?
    
    Time.at(time).strftime('%Y-%m-%d at %H:%M:%S')
  end


  def format_date(time)
    return '' if time.nil?

    Time.at(time).strftime('%Y-%m-%d')
  end

  def format_markdown(content)
    return '' if content.nil?

    temp = @markdown.render(content)
    "<div class=\"rendered-markdown\">#{temp}</div>"
  end

  #
  # encoders
  # 
  def encode_form_field(value)
    html_escape(value.to_s)
  end

  #
  #
  #
  
  def set_header(name, value)
    @header[name] = value
  end

  def load_file(path)
    if @@file_cache.has_key? path
      return @@file_cache[path]
    end

    file = File.open(path, 'r:UTF-8')
    data = file.read
    file.close
    @@file_cache[path] = data
    data
  end

  def load_template(path)
    if @@template_cache.has_key? path
      return @@template_cache[path]
    end

    erb = load_file(path)
    template = ERB.new erb
    @@template_cache[path] = template
    template
  end

  def is_rendered?(path)
    @@rendered_cache.has_key? path
  end

  def ensure_can_edit()
    # Ensure authenticated session that can edit.
    if @context[:session].nil?
     raise ClientErrorUnauthorized.new
   end
   if @context[:session]["can_edit"] == 0
     raise ClientErrorForbidden.new
   end
 end

  def can_edit?()
    # Ensure authenticated session that can edit.
    @context[:session] && @context[:session]["can_edit"] == 1
  end
  
  def get_rendered(path)
    if @@rendered_cache.has_key? path
      return @@rendered_cache[path]
    end
    nil
  end
  
  def set_rendered(path, rendered)
    @@rendered_cache[path] = rendered
    rendered
  end

  def include_partial(partial_name)
    begin 
      dir = File.dirname(File.realpath(__FILE__))
      path = "#{dir}/../templates/partials/#{partial_name}.html.erb"
      template = load_template(path)
      rendered = template.result binding
      set_rendered(path, rendered)
    rescue 
      puts "Error including partial '#{partial_name}'"
      "Error including partial '#{partial_name}'" 
    end
  end

  def include_part(part_content_id)
    part = @site_db.get_content(part_content_id)
    template = ERB.new part['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(part_content_id, rendered)
  end

  def include_content()
    template = ERB.new @context[:content_item]['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(@context [:content_id], rendered)
  end


  def include_page_content()
    template = ERB.new @context[:page]['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(@context[:page]['id'], rendered)
  end


  def page_template()
    class_name = self.class.name
    path = "#{dir}/../templates/endpoints/#{class_name}.html.erb"
    load_template(path)
  end


  def fetch_page() 
    page = @site_db.get_content(@page_id)

    if page.nil?
      raise NotFound.new
    end

    content_type = @site_db.get_content_type page['content_type']

    return page, content_type
  end
  
  def handle_get()
    raise ClientErrorMethodNotAllowed.new 'GET'
  end

  def handle_post()
    raise ClientErrorMethodNotAllowed.new "POST #{self.class.name}"
  end

  def handle_put()
    raise ClientErrorMethodNotAllowed.new 'PUT'
  end

  def handle_delete()
    raise ClientErrorMethodNotAllowed.new 'DELETE'
  end

  def render_template(class_name = nil)
    dir = File.dirname(File.realpath(__FILE__))
    if class_name.nil?
      class_name = self.class.name
    end
    path = "#{dir}/../templates/endpoints/#{class_name}.html.erb"
    template = load_template(path)
    template.result binding
  end
  
  def render()
    case @context[:method]
    when 'GET'
      handle_get()
    when 'POST'
      handle_post()
    when 'PUT'
      handle_put()
    when 'DELETE'
      handle_delete()
    else
      raise ClientErrorMethodNotAllowed.new("ERROR - request method not handled: #{@context[:method]}")
    end
  end
end