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

after '/create/:slug' do |slug|
  session[:last_slug] = slug
  session["counter"] ||= 0
  session["counter"] += 1
end


###############################################################
# A Little Presentation Serving App....
get '/' do
  remember :most_recently_visited_resource, :value=>"/", :for_how_long=>tomorrow
  this_resource = "/"

  content=[]
  content << "<h1>Welcome to Sinatra!</h1>"
  content << "<h2>These are the routes available:</h2>"
  content << "<ul>"
  content << File.open("controller.rb").map do |line| 
    m=line.match(/^ *(get|put|delete|post) +['"]([^ ]*)['"](.*)/)
    !m.nil? ? "<a href='#{m[2]}'>#{m[1]}: #{m[2]}</a><br/>" : nil
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
  def each
    100.times { |i| yield "Next #{i}<br/>" }
  end
end
# return any object that would either be a valid Rack response, Rack body object or HTTP status code:
#   An Array with three elements: [status (Fixnum), headers (Hash), response body (responds to #each)]
#   An Array with two elements: [status (Fixnum), response body (responds to #each)]

#   A Fixnum representing the status code
get '/server_error' do 500; end
get '/not_found' do 404; end
get '/not_found2' do not_found; end
get '/not_found_with_template' do not_found(haml,404); end
get '/not_found_with_exception' do raise NotFound; end
class CustomException < Exception
  def code
    401
  end
end
get '/custom_exception' do raise CustomException; end
get '/partial' do [203, Stream.new ] end

#   An object that responds to #each and passes nothing but strings to the given block
get('/next') { Stream.new }


###############################################################
# Use Pony for email confirmations
require 'pony'
post '/course_evaluation' do
  Pony.mail :to => 'mamiano@nc.rr.com',
            :from => 'Mitch.Amiano@AgileMarkup.com',
            :subject => 'Course Evaluated!'
end



###############################################################
# Error Handling

# See helpers
# not_found do
  # 'This is nowhere to be found.'
# end
# error do
  # 'Sorry there was a nasty error - ' + env['sinatra.error'].name
# end
# doesn't work
# error MyCustomError do
#  'So what happened was...' + request.env['sinatra.error'].message
#end
#get '/bad_place_to_be' do
#  raise MyCustomError, 'something bad'
#end
# handler for code raised
error 403 do
  'Access forbidden'
end
# or explicitly 
# get '/secret' do
#   403
# end
# Or a range:
# error 400..510 do
#   'Boom'
# end





###############################################################
# stop a request within a filter or route use:
# halt
# halt 410
# halt 'this will be the body'
# halt 401, 'go away!'
# halt 402, {'Content-Type' => 'text/plain'}, 'revenge'


__END__

@@ layout
%html
  = yield

@@ index
%div.title Hello world!!!!! inline __END__ data 
