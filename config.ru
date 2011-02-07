require 'rubygems'
require 'bundler'

Bundler.require

require 'application'

use Rack::ShowExceptions

run Sinatra::Application
