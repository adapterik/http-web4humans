require 'erb'
require_relative '../Page'

class PageNotFound < Page
  @title = "Not Found | Adaptations"
  @template_name = "NotFound"
end