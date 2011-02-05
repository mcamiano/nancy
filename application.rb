require 'compass'        # CSS Generation Framework
require 'lessframework'  # Multiple form-factor CSS Grid Layout Framework
require 'sinatra'        # Core Web App Framework
require "sinatra/reloader" if development?  # Restart automatically after development changes
require 'sequel'         # Database <-> Object Mapper
require 'sinatra/sequel' # helper commands for using sequel 
require 'mysql'          # Native MySQL driver
require 'pony'           # Email composition
require 'haml'           # HTML Template D.S.L. in Ruby; works well with Compass
require 'sass'           # CSS generation D.S.L. in Ruby, part of Compass

def app property
  { :name => "default_app",
    :database_name => "default_app"
  }[property]
end


# See 
# http://www.sinatrarb.com/intro
###############################################################
# Startup can be run for a specified environment or all
# configure :test do ...  end
# configure :production do ... end
configure do
  # See
  # https://github.com/rtomayko/sinatra-sequel
  ###############################################################
  # Establish the database connection, for Heroku env or local
  # The Sequel ORM is accessed using the "database" object
  set :database, (ENV['SHARED_DATABASE_URL'] || "mysql://root@localhost:3306/#{app :name}") 

  # Run migrations if necessary; these execute exactly once per database
  Dir["db/migrations/[0-9]+.*.rb"].each { |migration| require migration }
  # puts "Database not connected" if !database
  # puts "Table 'foos' does not exist" if !database.table_exists?('foos')

  # Configure Compass using an external file or in-line
  # Compass.add_project_configuration(File.join(Sinatra::Application.root, 'compass.rb'))
  Compass.configuration do |config|  # Set the Compass configuration in-line
    config.project_path = File.dirname(__FILE__)
    # see http://compass-style.org/docs/tutorials/configuration-reference/
    # Defaults are listed first
    # config.project_type = :stand_alone | :rails  ... this is Sinatra, not Rails
    # config.environment = :production | :development 
    # config.http_path = "/"    # project root when deployed:
    config.css_dir = "public/stylesheets"
    config.sass_dir = "public/stylesheets/sass"
    config.images_dir = "public/images"
    config.javascripts_dir = "public/javascripts"
    # To enable relative paths to assets via compass helper functions. Uncomment:
    # config.relative_assets = true
    # config.output_style = :nested, :expanded, :compact, or :compressed.
    config.output_style = :nested
  end

  # Override settings 
  # set :root, File.dirname(__FILE__)
  # set :views, File.dirname(__FILE__) + '/views'
  # set :public, File.dirname(__FILE__) + '/public'
  # set :server, %w[thin mongrel webrick]
  # set :bind, 'localhost'
  # set :port, 3010
  # set :dump_errors, false
  set :sessions, true  # DANGER: Sinatra sessions are Cookie based; avoid anything sensitive!!!
  set :haml, { :format => :html5 }
  set :sass, Compass.sass_engine_options

  set :domain, ENV['URL'] || "localhost"
  set :images, Compass.configuration.images_dir 
  set :stylesheets, Compass.configuration.css_dir 
  set :scripts, Compass.configuration.javascripts_dir 
end

###############################################################
# Provide special mime type for handling send_file, static files
# mime_type :foo, 'text/foo'
# Use these mimetypes in content type declarations:
# content_type :foo
mime_type :css, 'text/css'


###############################################################
# Define helper methods here 
helpers do
  include Rack::Utils
  alias_method :cdata, :escape_html

  def partial(template, options={})
    haml template, options.merge(:layout => false)
  end

  def view(class_name, method_name, options={})
    haml :"#{class_name}/#{method_name}", options.merge(:layout => true)
  end

  def image_tag(image_name,alt_text=image_name,options={})
     attributes = { 
       :src=>"#{settings.images_root}/#{image_name}", 
       :alt=>"#{alt_text}", 
       :id=>"img_#{image_name}"
     }.merge(options).map{|k,v| ":#{k}=>'#{v}'"}.join(', ')
     haml "%img{ #{attributes} }"
  end

  def path_for uri
    "#{request.script_name}#{uri}"
  end

  def absolute_path_for uri
    schemeport="#{request.scheme}:#{request.port}"
    schemeport=request.scheme if ['http:80','https:443'].any?(schemeport)
    "#{schemeport}://#{request.host}#{port}#{request.script_name}#{uri}"
  end

  def el tagname, attributes
    tagname = tagname.strip
    tag_end = attributes.any? { |k,v| k == :_empty && v == true } ? " />" : " >"
    content = attributes[:_content] || ""
    html_attributes = attributes.reject{|k,v| k.to_s =~/^_.*/}
    html_attributes.empty? ? "<#{tagname}#{tag_end}" : "<#{tagname} #{html_attributes.map{|k,v| "#{k}='#{v}'"}.join(" ")}#{tag_end}#{content}</#{tagname}>"
  end

  # Useful for setting cookies
  def right_now 
    Time.now.getutc 
  end
  def tomorrow 
    Time.now.getutc+24*60*60 
  end
  def in_one_week 
    Time.now.getutc+7*24*60*60 
  end
  def encode stringy_thingy
    CGI::escape(stringy_thingy)
  end
  def decode urly_thingy
    CGI::unescape(urly_thingy)
  end
  def remember what, value, for_how_long
    return if what.nil?
    timespan = for_how_long || tomorrow
    response.set_cookie(what.to_s, :domain => settings.domain, :path => "/", :value => encode what.to_s, :expires => timespan)
  end
  def recall what
    return "" if what.nil?
    decode request.cookies[what]
  end

  ###############################################################
  # Application-specific methods and data
  def html_page n
    pages[n-1][:resource]
  end
  def page_resource_path
    "/resource/#{n}/page"
  end
  def page_narrative
    [
      { :title => "Let's Start!", :resource => "start",  },
      { :title => "What is Sinatra About?", :resource => "sinatra"},
      { :title => "Sinatra Minimalism", :resource => "minimalism"}, # Compare to Rails,PHP MVC vs Joomla/Drupal/WP
      { :title => "Hello World", :resource => "hello"},  
      { :title => "Hello, Heroku!", :resource => "heroku"},  # What is Heroku about?
      { :title => "Application Tooling", :resource => "tooling"},  # OSX, GIT, MacVim, MySQL, Ruby Gems, Bundler, RSpec, Sinatra, Compass, other gems
      { :title => "Organizing a Sinatra App", :resource => "organization"},
      { :title => "Layout and Composition", :resource => "layout"},   # How is HTML layout accomplished?
      { :title => "Hello, C.R.U.D.! (Hello World in a Form)", :resource => "hellocrud"},   # Sudoku, Counter, Clock, Data feeder
      { :title => "Who uses Sinatra?", :resource => "applications"},
      { :title => "Questions?", :resource => "questions"}
      { :title => "End", :resource => "end"}
    ]
  end

  def next_movement current_resource
    page_narrative[((page_narrative.find_index {|page| page[:resource] == current_resource } + 1) % page_narrative.count) || 0]
  end

  def previous_movement current_resource
    page_narrative[((page_narrative.find_index {|page| page[:resource] == current_resource } - 1) % page_narrative.count) || page_narrative.count-1]
  end

  ###############################################################
  # Error Handling
  not_found do
    'This is nowhere to be found.'
  end
  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end
end

###############################################################
# Optional Model
require 'model'
# Optional Controller with Actions
require 'controller'

###############################################################
# Default Routes HTTP Method Matching Routes
# Placing them here allows them to be overridden

get '/stylesheets/:file.css' do
  content_type :css, :charset => 'utf-8'
  sass(:"stylesheets/#{params[:file]}", Compass.sass_engine_options)
end

get '/:view_name/:resource' do
  view params[:view_name], params[:resource]
end
