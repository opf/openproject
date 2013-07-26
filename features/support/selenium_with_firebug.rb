#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Capybara.register_driver :selenium_with_firebug do |app|
  Capybara::Selenium::Driver
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.add_extension(File.expand_path("../firebug-1.11.4.xpi", __FILE__))
  profile.add_extension(File.expand_path("../firepath-0.9.7-fx.xpi", __FILE__))

  # Prevent "Welcome!" tab
  profile["extensions.firebug.currentVersion"] = "999"

  # Enable for all sites.
  profile["extensions.firebug.allPagesActivation"] = "on"

  # Enable all features.
  ['console', 'net', 'script'].each do |feature|
    profile["extensions.firebug.#{feature}.enableSites"] = true
  end

  profile['intl.accept_languages'] = 'en,en-us'

  Capybara::Selenium::Driver.new(app,
                                 :browser => :firefox,
                                 :profile => profile)
end

Before '@firebug' do
  Capybara.current_driver = :selenium_with_firebug
end

