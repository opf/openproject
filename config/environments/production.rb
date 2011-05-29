#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

#####
# Customize the default logger (http://ruby-doc.org/core/classes/Logger.html)
#
# Use a different logger for distributed setups
# config.logger        = SyslogLogger.new
#
# Rotate logs bigger than 1MB, keeps no more than 7 rotated logs around.
# When setting a new Logger, make sure to set it's log level too.
#
# config.logger = Logger.new(config.log_path, 7, 1048576)
# config.logger.level = Logger::INFO

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = false

# No email in production log
config.action_mailer.logger = nil
