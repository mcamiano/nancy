###############################################################
# Hello World

get '/hello world' do
   haml "%h1{ :style=>'font-size: 30pt;' } Hello World!"
end

get '/hello_world' do
   protected! 

   flash[:notice] = "Hello World!"
   @hello_world_message = 'Hi there!'
   appinfo[:hit_counter] = appinfo[:hit_counter]+1
   @hit_count = appinfo[:hit_counter]
   haml :"view_name/show", :layout => "layouts/application.html".to_sym
end






###############################################################
# Filters
# Before filters are evaluated before each request within the same context as the routes 
# and can modify the request and response. 
#   cookie ||= 0 # Set a default
    #cookie = cookie.to_i # Convert to an integer
    #cookie += 1 # Do something with the value
    #response.set_cookie("thing", 
                        #:value => "my cookie value",
                        #:domain => settings.domain,
                        #:path => "/protected/#{myPath}",
                        #:expires => tomorrow
                        ## :secure => true,
                        ## :httponly => true
                       #)
after '/hello/:user_name' do |user_name|
  session[:last_user] = user_name
  session[user_name+"_counter"] ||= 0
  session[user_name+"_counter"] += 1
end

get '/hello/:user_name' do |user_name|
  # 'Hello, '+user_name+'! you have been here '+(session[user_name+'_counter']||0).to_s() +' times.'
  "Hello #{user_name}!"
end

get '/hello' do
  redirect '/hello/stranger', 303
end



###############################################################
# A Little Presentation Serving App....
get '/' do
  remember :most_recently_visited_resource, :value=>"/", :for_how_long=>tomorrow
  this_resource = "/"

  content=[]
  content << "<h1>Welcome to Sinatra!</h1>"
  content << "<p>These paths are available:</p>"
  content << "<ul>"
  content << File.open("controller.rb").map do |line| 
    m=line.match(/^ *(get|put|delete|post) +['"]([^ ]*)['"](\sdo|\{)#(.*)?/)
    !m.nil? ? "<a href='#{m[2]}'>#{m[1]}: #{m[4].nil? ? m[2] : m[4]}</a><br/>" : nil
  end.reject(&:nil?).map {|line| "<li>#{line}</li>"}
  content << "</ul>"

  content << "<h2>Let's Get Started</h2>"
  content << next_link("end")
  content.join
end

PAGE_NARRATIVE.each_with_index do |step,idx|
  get "/resource/by_name/#{step[:resource]}" do
    content=[]
    remember :most_recently_visited_resource, :value=>step[:resource], :for_how_long=>tomorrow
    content << "<h2>#{step[:title]}</h2>"
    content << next_link(step[:resource])
    content << previous_link(step[:resource])
    content.join
  end
  get "/resource/by_class_and_id/page/#{idx}" do
    content=[]
    remember :most_recently_visited_resource, :value=>step[:resource], :for_how_long=>tomorrow
    content << "<h2>#{step[:title]} (page #{idx})</h2>"
    content << next_link(step[:resource])
    content << previous_link(step[:resource])
    content.join
  end
end
###############################################################




get '/resource/:id/page' do
  "Got Flarg"
end

post '/flarg' do # Supports nested Rails style form params
# <form> <input ... name="post[title]" /> <input ... name="post[body]" /> <input ... name="post[author]" /> </form>
# Gives params[:post] := {"post"=>{ "title"=>"", "body"=>"", "author"=>"" }}
  # params[:post][:title]
  "Posting the Flarg"
end

put '/flarg' do
  "A Flarg was Put"
end

delete '/flarg' do
  "Deleted A Flarg"
end


###############################################################
# Conditions
get '/', :agent => /Internet Explorer (\d\.\d)[\d\/]*?/ do
  "Use Firefox"
end

get '/', :host_name => /^admin\./ do
  "Admin Area, Access denied!"
end

get '/soup', :provides => 'html' do
  "No Soup For You!"
end

get '/', :provides => ['rss', 'atom', 'xml'] do
  "Feeds not implemented"
end

set(:probability) { |value| condition { rand <= value } }
get '/gamble', :probability => 0.1 do
  "You won!"
end
get '/gamble' do
  "You lose!"
end


###############################################################
# Ordinary matchers for URLs
#
get '/' do
  'Hello world!'
end

get %r{/hello/C([\w]+)C} do |name|
  "Hello, #{name}!"
end

get '/hello/to/*/and/*' do
  "Hello to #{params[:splat][0]} and #{params[:splat][1]}"
end

get %r{/hello/([\w]+)} do
  "Hello, #{params[:captures].first}!"
end

get '/hi/*.*' do
  "Hi #{params[:splat][0]} #{params[:splat][1]}"
end

get '/yodog/:first_name/:last_name' do |first,last|
  "Yo Dog, #{last}, #{first}"
end

get '/weather' do 
  redirect '/weather/', 303
end

get '/weather/:zip?' do |zip|
  content =[]
  if !zip.nil?
    apikey="13fa13d445725fb5"
    begin
      f = open("http://api.wunderground.com/api/#{apikey}/animatedradar/q/#{zip}.gif?newmaps=1&timelabel=1&timelabel.y=10&num=5&delay=50")
    rescue 
      content << "<h1>Sorry, Weather Underground Radar for #{zip} appears to be offline"
    else
      img_content = f.read
      base64_encoded_image = Base64.encode64(img_content)
      content << "<h1>Weather Underground Radar for #{zip}</h1>"
      content << "<img src='data:image/gif;base64,#{base64_encoded_image}' alt='Weather Underground Radar'/>"
    ensure 
      f.close if not f.nil?
    end
  else
    content << "<h1>Weather Underground Radar</h1>"
    content << "<p>Please enter a zip code: </p>"
    content << "<form>"
    content << "<input id='zip' type='text' value='' />"
    content << "<input id='go' type='button' value='Go' />"
    content << "</form>"
    content << %{
      <script>
      var load = function() {
        document.getElementById('go').addEventListener("click", function() {
          var zip = document.getElementById('zip').value;
          window.location = "/weather/"+zip;
        });
      };
      document.addEventListener("DOMContentLoaded", load, false);  
      </script>
    }
    content.join
  end
  
end


###############################################################
# punt processing 

# to the next matching route using pass:
get '/guess/:who' do
  pass unless params[:who] == 'Frank'
  'You got me!'
end
get '/guess/*' do
  'You missed!'
end

# Via redirect
# redirect '/stuff', 307 # forces the 307 return code
# redirect '/otherstuff', 303 # forces the 303 return code

# to a fixed route
# before '/unprotected/*' do 
#   request.path_info = "/" 
# end
# get "/" do
#   "all requests end up here"
# end


###############################################################
# access request parameters
get '/foo' do
  #request.body              # request body sent by the client (see below)

  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  "Hello #{data['name']}!"
  
  #request.scheme            # "http"
  #request.script_name       # "/example"
  #request.path_info         # "/foo"
  #request.port              # 80
  #request.request_method    # "GET"
  #request.query_string      # ""
  #request.content_length    # length of request.body
  #request.media_type        # media type of request.body
  #request.host              # "example.com"
  #request.get?              # true (similar methods for other verbs)
  #request.form_data?        # false
  #request["SOME_HEADER"]    # value of SOME_HEADER header
  #request.referer           # the referer of the client or '/'
  #request.user_agent        # user agent (used by :agent condition)
  #request.cookies           # hash of browser cookies
  #request.xhr?              # is this an ajax request?
  #request.url               # "http://example.com/example/foo"
  #request.path              # "/example/foo"
  #request.ip                # client IP address
  #request.secure?           # false
  #request.env               # raw env hash handed in by Rack
end




###############################################################
# Working with the Rack stack
# For Response object properties and methods, see
# http://rack.rubyforge.org/doc/classes/Rack/Response.html
# and
# http://rack.rubyforge.org/doc/classes/Rack/Response/Helpers.html
class Stream
  def initialize(start=0,increment=100)
    @start=start
    @increment=increment
  end
  def each
    @increment.times { |i| yield "#{i+@start} " }
    @start = last
  end
  def last
    @start+@increment
  end
end
#   An object that responds to #each and passes nothing but strings to the given block
get('/next') { Stream.new }
get '/stream' do 
  start_point = session[:last_partial]||0
  stream = Stream.new(start_point,1000)
  session[:last_partial] = stream.last
  [203, stream] 
end
get '/stream_reset'  do 
  session[:last_partial] = 0 
  redirect '/stream', 303
end


######################################################################################
# Other responses return any object that would either be a valid Rack response, 
# Rack body object or an HTTP status code:
#   An Array with three elements: [status (Fixnum), headers (Hash), response body (responds to #each)]
#   An Array with two elements: [status (Fixnum), response body (responds to #each)]
#   A Fixnum representing the status code
get '/forbidden' do 403; end
get '/not_found' do 404; end


###############################################################
# Demo 1

get '/contact_form' do
  view :contact, :'index.html'
end

###############################################################
# Demo 2
before '/evaluation/*' do
  protected!   # Require authentication
end

get '/evaluation' do
  redirect '/evaluation/index.html', 303
end

get  '/evaluation/:action' do 
  view "evaluation", params[:action]
end

put '/evaluation/' do
  protected!
  #
  # save the evaluation: need migration for evaluations table
  # get the one-time-pad for the student
  # get the id for the evaluation
  # if not saved return 4xx level error
  # if saved render show view for evaluation
  #
  content=[]
  answers_concatenated = (1..25).to_a.map do |index|
    params['evaluation']['answer'+index.to_s].to_s
  end.join(",")
  new_evaluation @student, params['evaluation']['section'].to_s, params['evaluation']['grade'], answers_concatenated

  content << "<h1>Thank You!</h1>"
  content << "<p>We appreciate the time you took to evaluate your course. Your participation provides valuable feedback to our instructors and administration.</p>"
  content << "<p>These are the answers you provided:<blockquote>"
  content << (1..25).each do |index|
    # content << "<br/>#{QUESTIONS[index-1]}: #{params['evaluation']['answer'+index.to_s].to_s}"
    content << "<br/>#{index}: #{params['evaluation']['answer'+index.to_s].to_s}"
  end
  content << "</blockquote></p>"
   
  [203,  content.join]
  # [201,  view "evaluation", "show"]
end


###############################################################
# Use Pony for email confirmations
require 'pony'
post '/pony_submission' do
  Pony.mail :to => 'mamiano@nc.rr.com',
            :from => 'Mitch.Amiano@AgileMarkup.com',
            :subject => 'Course Evaluated!'
end

__END__
