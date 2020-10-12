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

namespace :test do
  desc 'runs all tests'
  namespace :suite do
    task run: [:cucumber, :spec, 'spec:legacy']
  end
end

task('spec:legacy').clear

namespace :spec do
  begin
    require 'rspec/core/rake_task'

    desc 'Run the code examples in spec_legacy'
    task legacy: %w(legacy:unit legacy:functional legacy:integration)
    namespace :legacy do
      %w(unit functional integration).each do |type|
        desc "Run the code examples in spec_legacy/#{type}"
        RSpec::Core::RakeTask.new(type => 'spec:prepare') do |t|
          t.pattern = "spec_legacy/#{type}/**/*_spec.rb"
          t.rspec_opts = '-I spec_legacy'
        end
      end
    end
  rescue LoadError
    # when you bundle without development and test (e.g. to create a deployment
    # artefact) still all tasks get loaded. To avoid an error we rescue here.
  end
end

%w(spec).each do |type|
  if Rake::Task.task_defined?("#{type}:prepare")
    Rake::Task["#{type}:prepare"].enhance(['assets:prepare_op'])
  end
end
