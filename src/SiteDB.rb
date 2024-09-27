require 'sqlite3'
require 'securerandom'

class SiteDB 
  def initialize()
    dir = File.dirname(File.realpath(__FILE__))
    path = "#{dir}/../data/site.sqlite3"
    @path = path
    @db = open_db()
  end

  def open_db()
    db = SQLite3::Database.new @path
    db.results_as_hash = true
    db
  end


  def sort_clause(sort)
    if sort.nil?
      ''
    else
      column = sort[0]
      direction = if sort[1].start_with?('a')
        'ASC'
      else
        'DESC'
      end
      "order by #{column} #{direction}"
    end
  end

  def limit_clause(limit)
    if limit.nil? 
      ''
    else
      "limit #{limit}"
    end
  end

  # USERS

  def get_user_auth(username, password)
    authorization_record = @db.execute '
      select * 
      from users_auth 
      where user_id = ? and password = ?
    ', [username, password]

    if authorization_record.length == 0
      nil
    else 
      authorization_record[0]
    end
  end

  # AUTH & SESSIONS

  def create_session(user_id) 
    session_id = SecureRandom.uuid
    now = Time.now.to_i
    # session expires in 2 weeks.
    expires = now + 60 * 60 * 24 * 14
    @db.execute '
      insert into auth_sessions 
      (id, user_id, created, expires) 
      values 
      (?, ?, ?, ?)
    ', [session_id, user_id, now, expires] 
    session_id
  end

  def remove_session(session_id)
    @db.execute '
      delete from auth_sessions 
      where id = ?
    ', [session_id]
  end

  def get_session(session_id)
    query = '
      select 
        s.id as session_id,
        s.user_id as user_id,
        u.name as user_name,
        u.can_view as can_view,
        u.can_edit as can_edit,
        u.can_manage as can_manage,
        s.created as created,
        s.expires as expires
      from auth_sessions s, users u 
      where s.id = ? and s.user_id = u.id 
    '
    session = @db.execute query, [session_id]
    session[0]
  end

  def list_sessions()
    query = '
      select 
        s.id as session_id,
        s.user_id as user_id,
        u.name as user_name,
        u.can_view as can_view,
        u.can_edit as can_edit,
        u.can_manage as can_manage,
        s.created as created,
        s.expires as expires
      from auth_sessions s, users u 
      where s.user_id = u.id 
    '
    @db.execute query, []
  end

  def list_auth_sessions()
    query = '
      select 
        *
      from auth_sessions
    '
    @db.execute query, []
  end

  # NAVIGATION

  def get_endpoint(name, arity)
    record = @db.execute '
      select e.name, e.description, e.class
      from endpoints e
      where e.name = ? and e.arity = ?
    ', [name, arity]
    if record.length === 0
      get_endpoint('page', 1)
    else 
      record[0]
    end
  end

  def get_site()
    record = @db.execute 'select * from site'
    return record[0]
  end

  # CMS
 

  def list_content(content_type, sort: nil, limit: nil)
    query = "
      select
        c.*
      from content c
      where
        c.content_type = ?
      #{sort_clause(sort)}
      #{limit_clause(limit)}
    "
    content_list = @db.execute query, [content_type]
    content_list
  end


  def search_content(content_type, sort, search_text)
    order_by_clause = ''

    if not sort.nil? or sort.length > 0
      column = sort[0]
      direction = if sort[1].start_with?('a')
        'ASC'
      else
        'DESC'
      end
      order_by_clause += "order by #{column} #{direction}"
    end

    where_clause = 'where c.content_type = ?'
    query_params = [content_type]

    if not search_text.nil?
      where_clause += ' and (c.content like ? or c.title like ?)'
      query_params.push("%#{search_text}%", "%#{search_text}%")
    end
    
    query = "
      select
        c.*
      from content c
      #{where_clause}
      #{order_by_clause}
    "
    content_list = @db.execute query, query_params
    content_list
  end

  def get_content_type(content_type_id)
    query = '
      select 
       t.*
      from content_types t 
      where 
        t.id = ?
    '
    content_record = @db.execute query, [content_type_id]
    content_record[0]
  end

  def get_content(content_id)
    query = '
      select 
        c.*, t.class, t.noun as noun
      from content c, content_types t 
      where 
        c.content_type = t.id and 
        c.id = ?
    '
    content_record = @db.execute query, [content_id]
    content_record[0]
  end

  def delete_content(content_type, content_id)
    query = '
      delete 
      from content
      where 
        content_type = ? and 
        id = ?
    '
    @db.execute query, [content_type, content_id]
  end

  def update_content(content_id, changes)
    # TODO: apply rules to fields
    
    title = changes['title']
    author = changes['author']
    abstract = changes['abstract']
    content = changes['content']
    content_type = changes['content_type']

    last_updated = (Time.now.to_f).to_i
      
    query = '
      update content
      set title = ?, author = ?, content = ?, abstract = ?, last_updated = ?, content_type = ?
      where content.id = ?
    '
    @db.execute query, [title, author, content, abstract, last_updated, content_type, content_id]
  end

  def add_content(content_item)
    # TODO: apply rules to fields

    id = content_item['id']
    title = content_item['title']
    content = content_item['content']
    author = content_item['author']
    created = (Time.now.to_f).to_i
    last_updated = created
    content_type = content_item['content_type']

    query = '
      insert into content 
      (id, title, content, author, created, last_updated, content_type)
      values
      (?, ?, ?, ?, ?, ?, ?)
    '
    @db.execute query, [id, title, content, author, created, last_updated, content_type]

    get_content id
  end

  def get_endpoint(name, arity)
    query = '
      select e.name, e.description, e.class
      from endpoints e
      where e.name = ? and e.arity = ?
    '
    record = @db.execute query, [name, arity]
    if record.length === 0
      get_endpoint('page', 1) 
    else 
      record[0]
    end
  end

  def get_site()
    record = @db.execute 'select * from site'
    return record[0]
  end


  # Links
  
  def get_site(site_id)
    query = '
      select 
        * 
      from sites
      where 
        id = ?
    '
    link_record = @db.execute query, [site_id]
    link_record[0]
  end


  def delete_site(site_id)
    query = '
      delete 
      from sites
      where 
        id = ?
    '
    @db.execute query, [site_id]
  end


  def get_sites(sort: nil, limit: nil)
    query = "
      select
        *
      from sites
      #{sort_clause(sort)}
      #{limit_clause(limit)}
    "
    content_list = @db.execute query
    content_list
  end

  def update_site(site_id, changes)
    title = changes['title']
    url = changes['url']
    description = changes['description']
    abstract = changes['abstract']
    last_checked = changes['last_checked']
    last_status = changes['last_status']
      
    query = '
      update sites
      set title = ?, url = ?, abstract = ?, description = ?, last_checked = ?, last_status = ?
      where id = ?
    '
    @db.execute query, [title, url, abstract, description, last_checked, last_status, site_id]
  end  

  def add_site(changes)
    title = changes['title']
    url = changes['url']
    abstract = changes['abstract']
    description = changes['description']
    last_checked = changes['last_checked']
    last_status = changes['last_status']

    added = (Time.now.to_f).to_i
    id = changes['id'] or SecureRandom.uuid

    query = '
      insert into sites
      (id, title, abstract, description, url, added, last_checked, last_status)
      values
      (?, ?, ?, ?, ?, ?, ?, ?)
    '
    @db.execute query, [id, title, abstract, description, url, added, last_checked, last_status]
  end  

  # sites / urls 
  
  def list_sites(sort: nil, limit: nil, search: nil)
    query_params = []

    where_clause = ''
    if not search.nil?
      where_clause += 'where (title like ? or description like ? or url like ?)'
      query_params.push("%#{search}%", "%#{search}%", "%#{search}%")
    end

    query = "
      select
        *
      from sites
      #{where_clause}
      #{sort_clause(sort)}
      #{limit_clause(limit)}
    "

    content_list = @db.execute query, query_params
    content_list
  end
  
end