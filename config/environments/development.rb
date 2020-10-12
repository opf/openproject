#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

OpenProject::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Automatically refresh translations with I18n middleware
  config.middleware.use ::I18n::JS::Middleware

  # Do not eager load code on boot.
  config.eager_load = false

  # Asynchronous file watcher
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Show full error reports
  config.consider_all_requests_local = true

  # Enable caching in development
  config.action_controller.perform_caching = true

  # Don't perform caching for Action Mailer in development
  config.action_mailer.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Disable compression and asset digests, but disable debug
  config.assets.debug = false
  config.assets.digest = false

  # Suppress asset output
  config.assets.quiet = true unless config.log_level == :debug

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Send mails to browser window
  config.action_mailer.delivery_method = :letter_opener
end

ActiveRecord::Base.logger = Logger.new(STDOUT) unless String(ENV["SILENCE_SQL_LOGS"]).to_bool
