require 'compass'        # CSS Generation Framework
require 'sinatra'        # Core Web App Framework
require "sinatra/reloader" if development?  # Restart automatically after development changes
require 'sequel'         # Database <-> Object Mapper
require 'sinatra/sequel' # helper commands for using sequel 
require 'mysql'          # Native MySQL driver
require 'pony'           # Email composition
require 'haml'           # HTML Template D.S.L. in Ruby; works well with Compass
require 'sass'           # CSS generation D.S.L. in Ruby, part of Compass
require 'rack-flash'
require 'html5-boilerplate'


APP = { :name => "default_app",
    :database_name => "default_app"
}

# See 
# http://www.sinatrarb.com/intro
###############################################################
# Startup can be run for a specified environment or all
# configure :test do ...  end
# configure :production do ... end
configure do
  use Rack::Flash

  # TODO: convert this to a parse of a static file
  STUDENTS = [
    { :username=>'johnny', :pad=>'8675309', :courses=>['ENG301:01', 'MAT200:43', 'PHY333:HO'] },
    { :username=>'mary', :pad=>'ABCDEF9', :courses=>['PHI101:03', 'MAT200:43', 'SOC111:01'] },
    { :username=>'george', :pad=>'GEORGE1', :courses=>['PHI101:03', 'MAT200:43', 'PHY333:HO'] }
  ]

  ###############################################################
  # See
  # https://github.com/rtomayko/sinatra-sequel
  # Establish the database connection, for Heroku env or local
  # The Sequel ORM is accessed using the "database" object
  set :database, (ENV['SHARED_DATABASE_URL'] || "mysql://root@localhost:3306/#{APP[:name]}") 

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
    config.css_dir = "/public/stylesheets"
    config.sass_dir = "stylesheets/sass"
    config.images_dir = "/public/images"
    config.javascripts_dir = "/javascripts"
    # To enable relative paths to assets via compass helper functions. Uncomment:
    config.relative_assets = true
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
  set :images_dir, Compass.configuration.images_dir 
  set :images_path, Compass.configuration.images_dir.gsub(/\/public(.*)/, '\1')
  set :stylesheets_dir, Compass.configuration.css_dir 
  set :stylesheet_source, Compass.configuration.sass_dir 
  set :scripts_dir, Compass.configuration.javascripts_dir 
end

###############################################################
# Provide special mime type for handling send_file, static files
# mime_type :foo, 'text/foo'
# Use these mimetypes in content type declarations:
# content_type :foo
mime_type :css, 'text/css'
mime_type :js, 'text/javascript'
mime_type :png, 'image/png'


###############################################################
# Define helper methods here 
helpers do
  include Rack::Utils
  alias_method :cdata, :escape_html

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    # Check credentials against one-time-pads for this semester
    @student = find_student_by_credentials @auth.credentials
    @auth.provided? && @auth.basic? && @auth.credentials && !@student.nil?
  end

  def find_student_by_credentials credentials
    STUDENTS.detect { |student| [student[:username], student[:pad]] == credentials }
  end

  # TODO: figure out how to pull this in without pasting
  # include Html5BoilerplateHelper
  # Create a named haml tag to wrap IE conditional around a block
  # http://paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither
  def ie_tag(name=:body, attrs={}, &block)
    attrs.symbolize_keys!
    haml_concat("<!--[if lt IE 7 ]> #{ tag(name, add_class('ie6', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if IE 7 ]>    #{ tag(name, add_class('ie7', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if IE 8 ]>    #{ tag(name, add_class('ie8', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if IE 9 ]>    #{ tag(name, add_class('ie9', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if (gte IE 9)|!(IE)]><!-->".html_safe)
    haml_tag name, attrs do
      haml_concat("<!--<![endif]-->".html_safe)
      block.call
    end
  end
  def google_api_key
    APP[:google_api_key]
  end
  def google_account_id
    APP[:google_account_id]
  end
  def ie_html(attrs={}, &block)
    ie_tag(:html, attrs, &block)
  end
  def ie_body(attrs={}, &block)
    ie_tag(:body, attrs, &block)
  end

  def app property
    APP[property]
  end

   # Override render to make it support rails-like syntax
  # See http://steve.dynedge.co.uk/2010/04/14/render-rails-style-partials-in-sinatra/
  def render(*args)
    if args.first.is_a?(Hash) && args.first.keys.include?(:partial)
      return haml "layouts/_#{args.first[:partial]}.html".to_sym, :layout => false
    else
      super
    end
  end
  
  def partial(template, options={})
    haml template, options.merge(:layout => "layouts/application.html".to_sym)
  end

  def view(view_name, method_name, options={})
    haml :"#{view_name.to_s}/#{method_name.to_s}", options.merge(:layout => "layouts/application.html".to_sym)
  end

  def serve_static_file(file_name)
    File.read(File.join('public', file_name.to_s))
  end

  def image_tag(image_name,alt_text=image_name,options={})
     attributes = { 
       :src=>"#{settings.images_path}/#{image_name}", 
       :alt=>"#{alt_text}", 
       :id=>"img_#{image_name}"
     }.merge(options).map{|k,v| ":#{k}=>'#{v}'"}.join(', ')
     haml "%img{ #{attributes} }"
  end
  
 def stylesheet_link_tag(stylesheet_name,options={})
     attributes = { 
       :href=>"#{settings.stylesheets_dir}/#{stylesheet_name}.css", 
       :media=>"all", 
       :rel=>"stylesheet",
       :type=>"text/css"
     }.merge(options).map{|k,v| ":#{k}=>'#{v}'"}.join(', ')
     haml "%link{ #{attributes} }"
  end

 def javascript_include_tag(script_name,options={})
     attributes = { 
       :src=> (script_name.to_s =~ /^\/\//) ? script_name.to_s : "#{settings.scripts_dir}/#{script_name}.js", 
       :type=>"text/javascript"
     }.merge(options).map{|k,v| ":#{k}=>'#{v}'"}.join(', ')
     haml "%script{ #{attributes} }"
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



  #####################################################################
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
    CGI::escape(stringy_thingy||"")
  end
  def decode urly_thingy
    CGI::unescape(urly_thingy||"")
  end
  def remember(what, options ={} ) # options := value, for_how_long
    return if what.nil?
    timespan = options[:for_how_long] || tomorrow
    response.set_cookie(what.to_s, 
                        :domain => settings.domain, 
                        :path => "/", 
                        :value => encode(options[:value]||""), 
                        :expires => timespan)
  end
  def recall what
    return "" if what.nil?
    decode request.cookies[what]
  end



  #####################################################################
  # Application-specific methods and data for a little presentation app
  def presentation_page n
    pages[n-1][:resource]
  end
  def page_resource_path n
    "/resource/by_class_and_id/page/#{n}"
  end
  def named_page_resource_path name
    "/resource/by_name/#{name}"
  end
  PAGE_NARRATIVE = [ 
      { :title => "Let's Start!", :resource => "start"},
      { :title => "What is Sinatra About?", :resource => "sinatra"},
      { :title => "Sinatra Minimalism", :resource => "minimalism"}, # Compare to Rails,PHP MVC vs Joomla/Drupal/WP
      { :title => "Hello World", :resource => "hello"},  
      { :title => "Hello, Heroku!", :resource => "heroku"},  # What is Heroku about?
      { :title => "Application Tooling", :resource => "tooling"},  # OSX, GIT, MacVim, MySQL, Ruby Gems, Bundler, RSpec, Sinatra, Compass, other gems
      { :title => "Organizing a Sinatra App", :resource => "organization"},
      { :title => "Layout and Composition", :resource => "layout"},   # How is HTML layout accomplished?
      { :title => "Hello, C.R.U.D.! (Hello World in a Form)", :resource => "hellocrud"},   # Sudoku, Counter, Clock, Data feeder
      { :title => "Who uses Sinatra?", :resource => "applications"},
      { :title => "Questions?", :resource => "questions"},
      { :title => "End", :resource => "end"}
    ]
  def next_movement current_resource
    PAGE_NARRATIVE[((PAGE_NARRATIVE.find_index {|page| page[:resource] == current_resource } + 1) % PAGE_NARRATIVE.count) || 0][:resource]
  end
  def previous_movement current_resource
    PAGE_NARRATIVE[((PAGE_NARRATIVE.find_index {|page| page[:resource] == current_resource } - 1) % PAGE_NARRATIVE.count) || PAGE_NARRATIVE.count-1][:resource]
  end
  def next_link resource
    "<a class='button_next' href='#{named_page_resource_path(next_movement(resource))}'>Next</a>"
  end
  def previous_link resource
    "<a class='button_previous' href='#{named_page_resource_path(previous_movement(resource))}'>Previous</a>"
  end

  #####################################################################
  # Application-specific methods and data for a course evaluations app
  QUESTIONS = [
    "My ability to think critically and analytically has been improved as a result of this course.",
    "My writing skills and my ability to express myself orally have been improved.",
    "The stated goals and objectives for the course were consistent with what was actually taught.",
    "The basis for determining the final grade is clearly reflected on the course syllabus.",
    "Evaluation procedures (tests, papers, discussions, etc.) covered the important aspects.",
    "Grade evaluation feedback was impartial and fair.",
    "The instructor followed the schedule on the syllabus.",
    "The instructor showed a mastery of the subject matter and was well prepared for class.",
    "The instructor was articulate and able to clearly explain important subject-matter concepts.",
    "The instructor supplemented the basic textbook material with additional readings/research.",
    "I was required to conduct library research in order to complete at least one assignment.",
    "The instructor used a variety of instructional approaches which enhanced learning.",
    "The instructor was courteous and responsive when students raised questions in class.",
    "The instructor was enthusiastic about the subject area.",
    "The instructor incorporated computer and/or Internet technology in classroom instruction.",
    "The textbooks and reading assignments were appropriate for the course.",
    "The instructor returned quizzes, examinations, and assignments in a timely manner.",
    "The instructor was available for consultation during his/her posted office hours.",
    "The instructor used class time effectively.",
    "Content was well organized and presented in a logical sequence.",
    "The pace of the course was appropriate.",
    "The instructor created an atmosphere in class that promoted learning.",
    "The instructor encouraged students to participate in class discussions and to ask questions.",
    "The instructor provided feedback as to how well I was doing in the course.",
    "The course was a valuable experience and I would take another course taught by this instructor."
  ]

  ###############################################################
  # Error Handling
  not_found do 
    serve_static_file "404.html"
  end
  error do
    'OW, Something Went Very Wrong Here. (' + env['sinatra.error'].username + ')'
  end
  # handler for code raised
  error 403 do
    'Access forbidden'
  end
end

#get '/:view_name/:resource' do
#  view params[:view_name], params[:resource]
#end

###############################################################
# Optional Model
require 'model'
# Optional Controller with Actions
require 'controller'

###############################################################
# Default Routes HTTP Method Matching Routes
# Placing them here allows them to be overridden

get '/public/stylesheets/*.css' do
  content_type :css, :charset => 'utf-8'
  sass File.join(settings.stylesheet_source, params[:splat]).to_sym, Compass.sass_engine_options
end
