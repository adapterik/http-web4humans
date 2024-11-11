
require 'nokogiri'
require 'json'
require_relative 'db'

class PageFixer
  def initialize(data_dir)
    @data_dir = data_dir
    @db = DB.new "#{@data_dir}/db.csv"
  end


  def fix_pages()
    # get the db
    db = @db.read

    db.each do |page_id, path, status, *extra|
      next if status != 'complete'

      page_name = "page_#{page_id}"
      page_path = "#{@data_dir}/pages/#{page_name}"
  
      doc = Nokogiri::HTML(page)
    
      File.open "#{page_path}.parsed.html", 'w' do |file|
        file.write(doc.to_s)
      end

    end


    # Using the index, go through pages, fixing...
    

  end
end

def main()
  data_dir = ARGV[0]

  fixer = PageFixer.new data_dir
  fixer.fix_pages
end