# 
# Rackup config

# Main.rb is the main entrypoint for the app 
require './src/Main'
require 'rack'

use Rack::Static,
    :urls => [
      "/audio", "/css", "/style", "/downloads", "/ext", "/images",
      "/js", "/less", "/scripts", "/multimedia",
      "/favicon.ico", "/favicon.png"],
    :root => "public"

# All Main.rb requires to get started, is the home directory.
# The rest is all convention
# See docs/design.md
run Main.new(ENV['HOME_DIR'])
