#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

guard :rspec, cmd: 'spring rspec --format d' do
  require 'guard/rspec/dsl'

  dsl = Guard::RSpec::Dsl.new(self)
  rspec = dsl.rspec
  watch(rspec.spec_helper)  { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  watch(/^modules\/(.+)\/spec\/(.+)_helper\.rb$/)   { |m| "modules/#{m[1]}/spec" }
  watch(/^modules\/(.+)\/spec\/support\/(.+)\.rb$/) { |m| "modules/#{m[1]}/spec" }
  watch(/^modules\/(.*)\/app\/(.+)\.rb$/)           { |m| "modules/#{m[1]}/spec/#{m[2]}_spec.rb" }
  watch(/^modules\/(.*)\/spec\/(.+)_spec\.rb$/)

  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
  rails = dsl.rails(view_extensions: %w[erb slim])
  watch(rails.spec_helper)                 { rspec.spec_dir }
  watch(rails.app_controller)              { "#{rspec.spec_dir}/controllers" }

  dsl.watch_spec_files_for(rails.app_files)
  dsl.watch_spec_files_for(rails.views)

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("mailers/#{m[1]}_mailer"),
      rspec.spec.call("controllers/#{m[1]}_controller"),
      rspec.spec.call("requests/#{m[1]}_controller")
    ]
  end

  watch(/^lib\/(.+)\.rb$/)                            { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})                  { 'spec' }
  watch('config/routes.rb')                           { 'spec/routing' }
  watch('app/controllers/application_controller.rb')  { 'spec/controllers' }

  # Capybara request specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
end
