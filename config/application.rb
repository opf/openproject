#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../boot', __FILE__)

require 'benchmark'
module SimpleBenchmark
  #
  # Measure execution of block and display result
  #
  # Time is measured by Benchmark module, displayed time is total
  # (user cpu time + system cpu time + user and system cpu time of children)
  # This is not wallclock time.
  def self.bench(title)
    $stderr.print "#{title}... "
    result = Benchmark.measure do
      yield
    end
    $stderr.printf "%.03fs\n", result.total
  end
end

require 'rails/all'
require 'active_support'
require 'active_support/dependencies'

ActiveSupport::Deprecation.silenced = Rails.env.production? && !ENV['OPENPROJECT_SHOW_DEPRECATIONS']

if defined?(Bundler)
  # lib directory has to be added to the load path so that
  # the open_project/plugins files can be found (places under lib).
  # Now it would be possible to remove that and use require with
  # lib included but some plugins already use
  #
  # require 'open_project/plugins'
  #
  # to ensure the code to be loaded. So we provide a compaibility
  # layer here. One might remove this later.
  $LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
  require 'open_project/plugins'

  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups(:opf_plugins))
end

require File.dirname(__FILE__) + '/../lib/open_project/configuration'
require File.dirname(__FILE__) + '/../app/middleware/reset_current_user'

module OpenProject
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Use Rack::Deflater to gzip/deflate all the responses if the
    # HTTP_ACCEPT_ENCODING header is set appropriately. As Rack::ETag as
    # Rack::Deflater adds a timestamp to the content which would result in a
    # different ETag on every request, Rack::Deflater has to be in the chain of
    # middlewares after Rack::ETag.  #insert_before is used because on
    # responses, the middleware stack is processed from top to bottom.
    config.middleware.insert_before Rack::ETag,
                                    Rack::Deflater,
                                    if: lambda { |_env, _code, headers, _body|
                                      # Firefox fails to properly decode gzip attachments
                                      # We thus avoid deflating if sending gzip already.
                                      content_type = headers['Content-Type']
                                      content_type != 'application/x-gzip'
                                    }

    config.middleware.use Rack::Attack
    # Ensure that tempfiles are cleared after request
    # http://stackoverflow.com/questions/4590229
    config.middleware.use Rack::TempfileReaper
    config.middleware.use ::ResetCurrentUser

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.enable_dependency_loading = true
    config.autoload_paths << Rails.root.join('lib').to_s
    config.autoload_paths << Rails.root.join('lib/constraints').to_s

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Add locales from crowdin translations to i18n
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'crowdin', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Fall back to default locale
    config.i18n.fallbacks = true

    # Enable cascade key lookup for i18n
    I18n.backend.class.send(:include, I18n::Backend::Cascade)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Load any local configuration that is kept out of source control
    # (e.g. patches).
    if File.exists?(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
      instance_eval File.read(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
    end

    # initialize variable for register plugin tests
    config.plugins_to_test_paths = []

    # Configure the relative url root to be whatever the configuration is set to.
    # This allows for setting the root either via config file or via environment variable.
    config.action_controller.relative_url_root = OpenProject::Configuration['rails_relative_url_root']

    config.to_prepare do
      # Rails loads app/views paths of all plugin on each request and appends it to the view_paths.
      # Thus, they end up behind the core view path and core views are found before plugin views.
      # To change this behaviour, we just reverse the view_path order on each request so plugin views
      # take precedence.
      ApplicationController.view_paths = ActionView::PathSet.new(ApplicationController.view_paths.to_ary.reverse)
      ActionMailer::Base.view_paths = ActionView::PathSet.new(ActionMailer::Base.view_paths.to_ary.reverse)
    end

    # Load API files
    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    OpenProject::Configuration.configure_cache(config)

    config.active_job.queue_adapter = :delayed_job

    config.action_controller.asset_host = OpenProject::Configuration['rails_asset_host']
  end
end
