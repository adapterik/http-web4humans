require_relative './EndpointHandler'

class HomeContentList < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @content_id = context[:endpoint_name]

    @tab = context[:arguments][0]

    sort_column_param = @context[:params]['sort-column']

    if sort_column_param.nil?
      @sort_column = 'title'
    else
      @sort_column = sort_column_param
    end

    sort_direction_param = @context[:params]['sort-direction']
    if sort_direction_param.nil?
      @sort_direction = 'ascending'
    else
      @sort_direction = sort_direction_param
    end
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = format_markdown fulfilled_content
    set_rendered(@context[:content_id], rendered)
  end

  def include_column_title(title, name)
    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../templates/partials/column-title.html.erb"
    template = load_template(path)
    
    template.result_with_hash({
      :tab => @tab,
      :current_sort_column => @sort_column, 
      :current_sort_direction => @sort_direction,
      :column_name => name,
      :title => title
    })

    # TODO: can cache if the key includes the binding variables...
    # set_rendered(path, rendered)
  end

  def handle_get_content_list()
    
  end

  def handle_get_home()
    
  end

  def handle_get()
    @context[:tab] = @tab

    if @tab == 'home' 
      handle_get_home()
    else
      handle_get_content_list
    end

    content_type_id = case @tab
    when 'pages' 
      'page'
    when 'articles' 
      'article'
    when 'blog'
      'blog'
    when 'thoughts' 
      'thought'
    when 'projects' 
      'project'
    end

    # Here we fetch the associated item
    content = @site_db.get_content(@content_id)
  
    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content_id = 'not_found'
        content = @site_db.get_content(content_id)
        content[:original_content_id] = original_content_id
        content_list = []
    else
        sort = [@sort_column, @sort_direction]
        # content_list = @site_db.list_content(content_type_id, sort)
        # 
        
        search = @context[:params]['search']
        content_list = @site_db.search_content(content_type_id, sort, search)
    end

    @content_type_id = content_type_id

    @content_type = @site_db.get_content_type content_type_id
    

    # We now abstract the "page" to be anything that affects the overall 
    # and generic information about the page.
    @context[:page] = {
      'title' => content['title']
    }

    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    @context.merge!({
      site: @site,
      content_id: @content_id,
      content: content,
      content_list: content_list,
      env: {
        request: request
      },
    })

    dir = File.dirname(File.realpath(__FILE__))
    # class_name = content['content_type'].capitalize
    path = "#{dir}/../templates/endpoints/HomeContentList.html.erb"
    template = load_template(path)
    template.result binding
  end
end