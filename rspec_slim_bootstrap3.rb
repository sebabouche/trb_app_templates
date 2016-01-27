# Start with : rails new project_name -m ~/ruby/app_templates/trailblazer/rspec_slim_bootstrap3.rb -d postgresql


# ADD CURRENT DIRECTORY
def source_paths
  Array(super) + 
  [File.expand_path(File.dirname(__FILE__))]
end

# GENERAL
gem 'rails-i18n'
gem 'simple_form'
gem 'bootstrap-sass'
gem 'therubyracer', platforms: 'ruby'
gem 'bootstrap-kaminari-views'
gem 'slim-rails'

# TRAILBLAZER
gem 'trailblazer'
gem 'trailblazer-rails' # if you are in rails.
gem 'reform'
gem 'roar'

gem "virtus"
gem 'responders'

  # authentication / authorization
  gem 'tyrant', github: 'apotonick/tyrant'
  gem 'pundit'

  # cells
  gem 'cells'
  gem 'cells-slim'
  gem 'kaminari'
  gem 'kaminari-cells'

  # file upload
  gem 'paperdragon'

# VALIDATORS
gem 'email_validator'
gem 'phony_rails'
gem 'file_validators'


### DEVELOPMENT TEST GROUP
gem_group :development, :test do
  gem 'dotenv-rails'

  gem 'rspec-rails'
  gem 'rspec-cells'
  gem 'rspec-trailblazer', github: 'trailblazer/rspec-trailblazer'

  gem 'shoulda-matchers', require: false

  gem 'capybara', require: false
  gem 'selenium-webdriver'

  gem 'database_cleaner'
  gem 'launchy'
  gem 'factory_girl_rails'
end


# DEVELOPMENT GROUP
gem_group :development do
  gem 'thin'
  gem 'binding_of_caller', platforms: [:mri_21]
  gem 'quiet_assets'
  gem 'rails_layout'
end


# TEST GROUP
gem_group :test do
  gem 'memory_test_fix'
  gem 'sqlite3'
end


# REMOVE SPRING
gsub_file('Gemfile', "gem 'spring'", "")


# BUNDLE INSTALL
run 'bundle install' 


# APPLICATION.RB
inject_into_file 'config/application.rb', after: /^end$/ do
  "\n\nrequire 'trailblazer/rails/railtie'"
end
inject_into_file 'config/application.rb', after: "config.active_record.raise_in_transactional_callbacks = true" do
  "\n    config.generators do |g|\n      g.template_engine :slim\n    end"
end


# INITIALIZERS

generate 'simple_form:install'
generate 'simple_form:install --bootstrap' 
generate 'kaminari:views default -e slim'

inject_into_file 'app/assets/javascripts/application.js', :after => "//= require jquery_ujs" do
  "\n//= require bootstrap"
end

remove_file 'app/assets/stylesheets/application.css'
create_file 'app/assets/stylesheets/application.scss' do
  <<-eof
@import "bootstrap-sprockets";
@import "bootstrap";
  eof
end

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

# TRAILBLAZER INITIALIZER
initializer 'trailblazer.rb', <<-CODE
require "trailblazer/operation/dispatch"

Trailblazer::Operation.class_eval do
  include Trailblazer::Operation::Dispatch
end

require "roar/json/hal"

::Roar::Representer.module_eval do
  include Rails.application.routes.url_helpers
  # include Rails.app.routes.mounted_helpers

  def default_url_options
    {}
  end
end
CODE

# CELLS INITIALIZER
initializer 'cells.rb', <<-'CODE'
ActiveSupport::Notifications.subscribe "read_fragment.cells" do |name, start, finish, id, payload|
  Rails.logger.debug "CACHE: #{payload}"
end

ActiveSupport::Notifications.subscribe "write_fragment.cells" do |name, start, finish, id, payload|
  Rails.logger.debug "CACHE write: #{payload}"
end
CODE

# PAPERDRAGON INITIALIZER
initializer 'dragonfly.rb', <<-CODE
Dragonfly.app.configure do
  plugin :imagemagick

  datastore :file,
    :server_root => 'public',
    :root_path => 'public/images'
end
CODE

# TYRANT INITIALIZER
initializer 'tyrant.rb', <<-CODE
require "tyrant/railtie"
CODE

    
# APPLICATION CONTROLLER WITH TRB
remove_file 'app/controllers/application_controller.rb'
create_file 'app/controllers/application_controller.rb' do
  <<-CODE
class ApplicationController < ActionController::Base
  include Trailblazer::Operation::Controller

  protect_from_forgery with: :exception

  def tyrant
    Tyrant::Session::new(request.env["warden"])
  end
  helper_method :tyrant

  def process_params!(params)
    params.merge!(current_user: tyrant.current_user)
  end
  
  rescue_from Trailblazer::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    flash[:alert] = "Not authorized, my friend."
    redirect_to root_path
  end
end
  CODE
end


# HOME CONTROLLER
generate(:controller, 'home', 'index')
route "root to: 'home#index'"

 
# GITIGNORE (only if using VIM)
inject_into_file '.gitignore', "\n*.swp\n*swo", after: "/tmp"

git :init
git add: '.'
git commit: %Q{ -m "Initial commit" }

rake 'db:setup'
rake 'db:setup RAILS_ENV=test'

