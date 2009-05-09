# =========================
# base.rb
# Author: Michael Deering http://mdeering.com
#
# Absolute minimum that goes into every Rails app
# =========================
# TODO: Find out if we have access to the name of the application inside our template
#       without having to rely on the ask function
# TODO: Find a decent resource or guide for rails templates
#       and figure out how to include other templates or modules
# TODO: Add the config file setup for exception notification plugin
# TODO: Look at adding http://github.com/justinfrench/formtastic/tree/master to the base templat
# =========================

# FIXME: These functions do not belong here.
def download(location, destination)
  puts "Downloading #{location} => #{destination}"
  run "wget --directory-prefix=#{destination} #{location}"
end

def haml!
  run 'haml --rails .'
end

def piston(vendor_directory_name, repository_location)
  run "piston import #{repository_location} vendor/plugins/#{vendor_directory_name}"
end

def touch(*args)
  args = args.first if args.first.class == Array
  args.each do |file_location|
    next if File.file?(file_location)
    directory = File.dirname(file_location)
    basename  = File.basename(file_location)
    puts "Touching #{directory}/#{basename}"
    puts "Ran out of time for today TODO: Finish up touch function!"
  end
end

# application_name              = ask("What is the common name going to be used to reference this application?: ")
# freeze_to_edge                = yes?("Freeze rails gems ?")
# notification_email_recipients = ask('Enter the emails you wish to recieve application exception notifications seperated with just a space (joe@schmoe.com bill@schmoe.com): ')
# notification_sender_email     = ask('Enter the email address that you wish your application exception notifications to be sent out under ("Application Error" <app.error@myapp.com>): ')

rake 'rails:freeze:edge' # if freeze_to_edge

# =========================
# Initial clean up
# =========================

['public/favicon.ico', 'public/index.html', 'public/javascripts/*'].each do |file|
  puts "Removing #{file}"
  run "rm #{file}"
end

# Set up the local git repository
git :init

haml!
capify!

# 99.9% of the time we are going to use MySQL
file 'config/database.yml.sample',
%q{defaults: &defaults
  adapter:  mysql
  username: root
  password: 
  host: localhost
  encoding: utf8

development:
  <<:       *defaults
  database: application_development

test:
  <<:       *defaults
  database: application_test

production:
  <<:       *defaults
  database: application_development
}

# Grab the latest copy of jquery

# Start the .gitignore file
file '.gitignore',
%q{.DS_Store
coverage/*
log/*.log
db/*.db
db/*.sqlite3
db/schema.rb
tmp/**/*
doc/api
doc/app
config/database.yml
coverage/*
}

gem 'thoughtbot-factory_girl', :lib => 'factory_girl',  :source => 'http://gems.github.com'
gem 'thoughtbot-shoulda',      :lib => 'shoulda',       :source => 'http://gems.github.com'
gem 'mislav-will_paginate',    :lib => 'will_paginate', :source => 'http://gems.github.com'

# This version of annotate puts the scema at the bottom of 
# the file and also leaves out adding the schema version by default
piston 'annotate_models',    'git://github.com/bendycode/annotate_models.git'

# Asset packager don't go anywhere without it!
# Lets also setup the basic config file to work with here also.
piston 'asset_packager',     'git://github.com/sbecker/asset_packager.git'
download 'http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js', 'public/javascripts'
# Create working files for javascript
touch 'this.something'
touch ['public/javascripts/admin.js', 'public/javascripts/application.js', 'public/javascripts/public.js']
# Create working files for stylesheets
touch ['public/stylesheets/sass/admin.sass']
file 'config/asset_packages.yml',
%q{---
javascripts:
- admin:
  - jquery.min
  - application
  - admin
- public
  - jquery.min
  - application
  - public
stylesheets:
- admin:
  - admin
- public:
  - application
}

piston 'exception_notifier', 'git://github.com/rails/exception_notification.git'
initializer 'exception_notification.rb',
%q{# == Customization
# 
# By default, the notification email includes four parts: request, session,
# environment, and backtrace (in that order). You can customize how each of those
# sections are rendered by placing a partial named for that part in your
# app/views/exception_notifier directory (e.g., _session.rhtml). Each partial has
# access to the following variables:
# 
# * @controller: the controller that caused the error
# * @request: the current request object
# * @exception: the exception that was raised
# * @host: the name of the host that made the request
# * @backtrace: a sanitized version of the exception's backtrace
# * @rails_root: a sanitized version of RAILS_ROOT
# * @data: a hash of optional data values that were passed to the notifier
# * @sections: the array of sections to include in the email
# 
# You can reorder the sections, or exclude sections completely, by altering the
# ExceptionNotifier.sections variable. You can even add new sections that
# describe application-specific data--just add the section's name to the list
# (whereever you'd like), and define the corresponding partial. Then, if your
# new section requires information that isn't available by default, make sure
# it is made available to the email using the exception_data macro:
# 
#   class ApplicationController < ActionController::Base
#     ...
#     protected
#       exception_data :additional_data
# 
#       def additional_data
#         { :document => @document,
#           :person => @person }
#       end
#     ...
#   end
# 
# In the above case, @document and @person would be made available to the email
# renderer, allowing your new section(s) to access and display them. See the
# existing sections defined by the plugin for examples of how to write your own.
# 
# == Advanced Customization
# 
# By default, the email notifier will only notify on critical errors. For
# ActiveRecord::RecordNotFound and ActionController::UnknownAction, it will
# simply render the contents of your public/404.html file. Other exceptions
# will render public/500.html and will send the email notification. If you want
# to use different rules for the notification, you will need to implement your
# own rescue_action_in_public method. You can look at the default implementation
# in ExceptionNotifiable for an example of how to go about that.

ExceptionNotifier.exception_recipients = %w(joe@schmoe.com bill@schmoe.com)
ExceptionNotifier.sender_address = %("Application Error" <app.error@myapp.com>)
ExceptionNotifier.email_prefix = "[APP] "
}

piston 'rspec',              'git://github.com/dchelimsky/rspec.git'
piston 'rspec-rails',        'git://github.com/dchelimsky/rspec-rails.git'
generate("rspec")


