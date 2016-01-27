# ADD CURRENT DIRECTORY
def source_paths
Array(super) + 
[File.expand_path(File.dirname(__FILE__))]
end

remove_file 'Gemfile'
run 'touch Gemfile'


# GENERAL
add_source 'https://rubygems.org'

gem 'rails', '~>4.2'
gem 'pg'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'rails-i18n', '~> 4.0.0'
gem 'therubyracer', :platform=>:ruby
gem 'thin'
gem 'responders'
gem 'rails-timeago'

gem 'simple_form'

gem 'slim-rails'

gem 'bootstrap-sass'
gem 'bootstrap-kaminari-views'
gem 'font-awesome-rails'

# TRAILBLAZER
gem 'trailblazer'
gem 'trailblazer-rails' # if you are in rails.

gem 'reform'

gem 'cells'
gem 'cells-slim'

gem 'tyrant'
gem 'warden'
gem 'pundit'

gem 'responders'
gem 'roar'

gem 'kaminari'
gem 'kaminari-cells'

gem 'paperdragon'

gem 'virtus'

gem 'email_validator'
gem 'phony_rails'
gem 'file_validators'


### DEVELOPMENT TEST GROUP
gem_group :development, :test do
  gem 'dotenv-rails'
  gem 'byebug'
  gem 'web-console', '~> 2.0'

  gem 'minitest-rails-capybara'
  gem 'minitest-line'

  gem 'shoulda-matchers', require: false

  gem 'capybara'
  gem 'selenium-webdriver'

  gem 'database_cleaner'
  gem 'launchy'
  gem 'factory_girl_rails'
end


# DEVELOPMENT GROUP
gem_group :development do
  gem 'binding_of_caller', :platforms=>[:mri_21]
  gem 'quiet_assets'
  gem 'rails_layout'
end


# TEST GROUP
gem_group :test do
  gem 'memory_test_fix'
  gem 'sqlite3'
end

# GITIGNORE (only if using VIM)
remove_file '.gitignore'
create_file '.gitignore' do 
  <<-eof
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*
!/log/.keep
/tmp

# Ignore vim swap files
*.swp
*.swo
  eof
end


# TRAILBLAZER INITIALIZER
  create_file 'config/initializers/trailblazer.rb' do
    <<-eof
require 'trailblazer/autoloading'
    eof
  end

# CELLS INITIALIZER
  create_file 'config/initializers/cells.rb' do
    <<-'eof'
ActiveSupport::Notifications.subscribe "read_fragment.cells" do |name, start, finish, id, payload|
  Rails.logger.debug "CACHE: #{payload}"
end

ActiveSupport::Notifications.subscribe "write_fragment.cells" do |name, start, finish, id, payload|
  Rails.logger.debug "CACHE write: #{payload}"
end
    eof
  end


# PAPERDRAGON INITIALIZERS
create_file 'config/initializers/dragonfly.rb' do
  <<-eof
Dragonfly.app.configure do
  plugin :imagemagick

  datastore :file,
    :server_root => 'public',
    :root_path => 'public/images'
end
  eof
end

create_file 'config/initializers/paperdragon.rb' do
  <<-eof
Dragonfly.app.configure do
  plugin :imagemagick

  datastore :file,
    :server_root => 'public',
    :root_path => 'public/images'
end
  eof
end


# TYRANT INITIALIZER
create_file 'config/initializers/tyrant.rb' do
  <<-eof
require "tyrant/railtie"
  eof
end


# APPLICATION CONTROLLER WITH TRB
remove_file 'app/controllers/application_controller.rb'
create_file 'app/controllers/application_controller.rb' do
  <<-eof
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include Trailblazer::Operation::Controller
  require 'trailblazer/operation/controller/active_record'
  include Trailblazer::Operation::Controller::ActiveRecord # named instance variables.

  def tyrant
    Tyrant::Session.new(request.env['warden'])
  end

  helper_method :tyrant

  def process_params!(params)
    params.merge!(current_user: tyrant.current_user)
  end  
end
  eof
end


# BUNDLE INSTALL
run 'bundle install' 


# INITIALIZERS AND INITIAL GIT COMMIT
after_bundle do
  rake 'db:create'
  rake 'db:migrate'

  generate 'simple_form:install'

  generate 'simple_form:install --bootstrap' 

  inject_into_file 'app/assets/javascripts/application.js', :after => "//= require jquery_ujs" do
    "\n//=require bootstrap"
  end

  remove_file 'app/assets/stylesheets/application.css'
  create_file 'app/assets/stylesheets/application.scss' do
      <<-eof
@import "bootstrap-sprockets";
@import "bootstrap";
      eof
  end

  # HOME CONTROLLER
  generate 'controller home index'
  route "root to: 'home#index'"

  git :init
  git add: '.'
  git commit: %Q{ -m "Initial commit" }
end
