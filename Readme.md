Starting Up
-----------
Run the application with 
  bundle exec ruby application.rb

or, if rackup is in the path,
  rackup --port 3010 2>&1 | tee server.log
  
See bin/Run for an example 


Bundler Commands:
-----------------
When a new feature is added via a gem, it is usually sufficient just to run "bundle".
That does a "bundle install" to install the gems. 
Here are other common commands:

bundle check     # Inspect your bundle to see if you've met your applications requirements
bundle list      # List all gems in your bundle
bundle show [gemname] # Show source location of a specific gem in your bundle
bundle init      # Generate a skeleton Gemfile to start your path to using Bundler 
bundle update    # Refresh the Gemfile.lock for dependencies of specified and installed gems



Database Migrations
-------------------
Execute migrations with
  sequel -m data db/migrations/database.yml
  sequel -m data db/migrations/database.yml -M 1 # migrates to 001
  

Heroku Deployment
-----------------
Here is the heroku info:

http://young-sword-922.heroku.com/ | git@heroku.com:young-sword-922.git

Pushing To Heroku: git push heroku master
Rolling back a screwed up deployment: heroku rollback [ optional vN version number ]

Heroku processes: heroku ps
Heroku logs: heroku logs
 to write to a log: just write to stdout or stderr: puts "Hello, logs!"


Heroku Programming
------------------
Accessing Heroku config in Ruby: 
ENV["configvarname"]

Setting config variables in Heroku:
http://blog.leshill.org/blog/2010/11/02/heroku-environment-variables.html

Tunneling config variables through Sinatra settings:
set :prop_name, ENV['prop_name'] || 'development and/or default prop value'
Use as "settings.prop_name"

Tips here:
http://blog.heroku.com/archives/2009/3/5/32_deploy_merb_sinatra_or_any_rack_app_to_heroku/

Use PONY on Heroku to Send Mail: 
http://ididitmyway.heroku.com/past/2010/12/4/an_email_contact_form_in_sinatra/


Setting Cookies in Sinatra
--------------------------
use "request.cookies['cookiename'] to get them
use "response.set_cookie" to set them
use "response.delete_cookie('thing')" to get rid of them
see  rack-1.0.0/lib/rack/response.rb around line 56 for how they are implemented 






HAML Usage
----------
HAML is as simple as invoking it against a view with a layout file 

HAML is ugly for most HTML content. Use it for Ruby code, and use filters for anything else.
To quote Chris Eppstein,  "
Haml lets you pass any block of content through a filter. If you find yourself thinking that Haml is getting in the way, that’s probably because you aren’t using a filter. In any filter, you can use #{} to insert output from code. The following filters are available for processing your content:
:plain – Simply passes the filtered text through to the generated HTML.
:cdata – Surrounds the filtered text with a CDATA escape.
:escaped – Works the same as :plain, but HTML-escapes the text before placing it in the document.
:erb – Parses the filtered text with ERB – the Rails default template engine.
:textile – Parses the filtered text with Textile. Only works if RedCloth is installed.
:markdown – Parses the filtered text with Markdown. Only works if RDiscount, RPeg-Markdown, Maruku, or BlueCloth are installed
:maruku – Parses the filtered text with Maruku, which has some non-standard extensions to Markdown.
"

Adding Compass / LessFramework / HTML5 Boilerplate
--------------------------------------------------
Don't bother if what you are looking for is a framework.

SASS and Less are quite useful as macro languages for CSS. 
Yet they do not actually advance the starting point of the project. 
You still need to establish a visual repetoire and conventions for classes and tag overloading.

If you want to use a framework, Twitter Bootstrap or a variation of it is probably the most practical to use.
It actually does advance the project with "hit the ground running" conventions and code patterns. 
Bootstrap uses Less and there is at least one fork for Rails that uses SCSS/SASS.

Kickstrap is a very good bundle based on Bootstrap and HTML5Boilerplate. 
To use Kickstrap, Node.js and NPM are convenient. 



