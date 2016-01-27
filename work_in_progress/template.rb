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


# TEMPLATE ENGINE
  template_engine = ''
  if yes? 'Do you want to install slim? (y/n) - following choice: haml'
    template_engine = 'slim'
    gem 'slim-rails'
  end

  if yes? 'Do you want to install haml?(y/n)'
    template_engine = 'haml'
    gem 'haml', github: 'haml/haml', ref: '7c7c169'
    gem 'haml-rails'
  end


# BOWER
  if yes? 'Do you want to install bower? (y/n)'
    gem 'bower-rails'
  end


# FRONTEND FRAMEWORK
  front_end = ''
  if yes? 'Do you want to install Bootstrap 4 alpha? (y/n) - following choices: boostrap-sass, foundation'
    front_end = 'bootstrap'
    gem 'bootstrap', '~> 4.0.0.alpha1'
    gem 'bootstrap-glyphicons'
    gem 'bootstrap-kaminari-views'
    gem 'font-awesome-rails'
  end

  if yes? 'Do you want to install Bootstrap-sass? (y/n)'
    front_end = 'bootstrap'
    gem 'bootstrap-sass'
    gem 'bootstrap-kaminari-views'
    gem 'font-awesome-rails'
  end

  if yes? 'Do you qant to install Foundation? (y/n)'
    front_end = 'foundation'
    gem 'foundation-rails'
    gem 'foundation-icons-sass-rails'
  end


# TRAILBLAZER
  gem 'trailblazer'
  gem 'trailblazer-rails' # if you are in rails.

  gem 'reform'

  gem 'cells'
  if template_engine == 'slim'
    gem 'cells-slim'
  elsif template_engine == 'haml'
    gem 'cells-haml'
  end

  gem 'tyrant'
  gem 'warden'
  gem 'pundit'

  gem 'responders'
  gem 'roar'

  gem 'kaminari'
  gem 'kaminari-cells'

  gem 'paperdragon'

  gem 'virtus'


# VALIDATORS
  gem 'email_validator'
  gem 'phony_rails'
  gem 'file_validators'

  
# TEST FRAMEWORK
  test_framework = ''
  if yes? 'Do you want to test with Minitest? (y/n) - following choice Rspec'
    test_framework = 'minitest'
  end
  if yes? 'Do you want to test with RSpec? (y/n)'
    test_framework = 'rspec'
  end


### DEVELOPMENT TEST GROUP
  gem_group :development, :test do
    gem 'dotenv-rails'
    gem 'byebug'
    gem 'web-console', '~> 2.0'

    if test_framework == 'minitest'
      gem 'minitest-rails-capybara'
      gem 'minitest-line'

    elsif test_framework == 'rspec'
      gem 'rspec-rails'
      gem 'rspec-cells'
      gem 'rspec-trailblazer', git: "https://github.com/trailblazer/rspec-trailblazer.git"
    end

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

    if front_end == 'bootstrap'
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

    elsif front_end == 'foundation'
      generate 'simple_form:install --foundation'
    end

    if test_framework == 'rspec'
      generate 'rspec:install'
      remove_file 'spec/rails_helper.rb'
      create_file 'spec/rails_helper.rb' do
        <<-'eof'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'shoulda/matchers'
require 'database_cleaner'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

include ActionDispatch::TestProcess # for fixture_file_upload

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!
  
  config.include RSpec::Trailblazer::Matchers, type: :operation

  config.include Capybara::DSL

  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:example) do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after(:example) do
    DatabaseCleaner.clean
  end
end
        eof
      end

    elsif test_framework == 'minitest'
      #TODO
    end

    # HOME CONTROLLER
    generate 'controller home index'
    route "root to: 'home#index'"

    git :init
    git add: '.'
    git commit: %Q{ -m "Initial commit" }
  end
