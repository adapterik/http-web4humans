class DB  
  def initialize(file_path)
    @file_path = file_path
    @current_index = 0
    # @cached = read_or_create
    @cached = read
    @current_index = @cached.length

    @indexed_by_uri = {}
    index_by_uri
  end

  def clear()
    # Touch the file. If clear, remove all contents
    File.open @file_path, 'w' do |file|
      file.write ''
    end
    []
  end

  # def read_or_create()
  #   if not File.exist? @file_path
  #     clear
  #   end
  #   read
  # end

  def read()
    if not File.exist? @file_path
      File.write @file_path, ''
    end
    CSV.read @file_path, converters: :integer
  end

  def index_by_uri()
    @indexed_by_uri = {}
    @cached.map do |id, parent_page_id, uri, status, *extra|
      @indexed_by_uri[uri.to_s] = id
    end
  end

  def size()
    @cached.length
  end

  def save()
    output_string = CSV.generate do |csv|
      @cached.each do |row|
        csv << row
      end
    end
    File.open @file_path, 'w' do |file|
      file.write output_string
    end
  end

  def has_uri?(uri)
    @indexed_by_uri.has_key? uri.to_s
  end

  def page_for_uri(uri)
    page_id = @indexed_by_uri[uri.to_s]

    if not page_id.nil?
      # a bit hacky?
      @cached[page_id - 1]
    else
      nil
    end
  end

  def add_entry(parent_page_id, uri, status, *extra)
    @current_index += 1
    @cached.append [@current_index, parent_page_id, uri.to_s, status, *extra]
    @indexed_by_uri[uri.to_s] = @current_index
    save
    @current_index
  end

  def set_entry_status(page_id, new_status, *new_extra)
    new_cached = @cached.map do |id, parent_page_id, uri, status, *extra|
      if id == page_id
        status = new_status
        extra = new_extra
      end
      [id, parent_page_id, uri, status, *extra]
    end
    @cached = new_cached
    save
  end

  def set_entry_error(page_id, code, message)
    set_entry_status page_id, 'error', code, message
  end

  def set_entry_inprogress(page_id)
    set_entry_status page_id, 'inprogress'
  end

  def set_entry_complete(page_id, elapsed_time)
    set_entry_status page_id, 'complete', elapsed_time
  end

  def has_entry?(page_id)
    @cached.each do |id, parent_page_id, uri, status, *extra|
      if id == page_id
        return true
      end
    end
    return false
  end

end