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

Capybara.register_driver :selenium_with_firebug do |app|
  Capybara::Selenium::Driver
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.add_extension(File.expand_path('../firebug-1.11.4.xpi', __FILE__))
  profile.add_extension(File.expand_path('../firepath-0.9.7-fx.xpi', __FILE__))

  # Prevent "Welcome!" tab
  profile['extensions.firebug.currentVersion'] = '999'

  # Enable for all sites.
  profile['extensions.firebug.allPagesActivation'] = 'on'

  # Enable all features.
  ['console', 'net', 'script'].each do |feature|
    profile["extensions.firebug.#{feature}.enableSites"] = true
  end

  profile['intl.accept_languages'] = 'en,en-us'

  Capybara::Selenium::Driver.new(app,
                                 browser: :firefox,
                                 profile: profile)
end

Before '@firebug' do
  Capybara.current_driver = :selenium_with_firebug
end
