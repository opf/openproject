#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :spec do
  desc 'Run the code examples in spec'
  begin
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(core: 'spec:prepare') do |t|
      t.exclude_pattern = ''
    end

    desc "Run specs w/o api, features, controllers, requests and models"
    RSpec::Core::RakeTask.new(misc: 'spec:prepare') do |t|
      t.exclude_pattern = 'spec/{api,models,controllers,requests,features}/**/*_spec.rb'
    end

    desc "Run requests specs for api v3"
    RSpec::Core::RakeTask.new('api:v3:requests' => 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    desc "Run specs for api v3 except requests"
    RSpec::Core::RakeTask.new('api:v3:misc' => 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/**/*_spec.rb'
      t.exclude_pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    sub_types = begin
            dirs = Dir['./spec/{api,features}/**/*_spec.rb'].
              map { |f| f.sub(/^\.\/(spec\/\w+\/\w+)\/.*/, '\\1') }.
              uniq.
              select { |f| File.directory?(f) }
            Hash[dirs.map { |d| ["#{d.split('/').second}:#{d.split('/').last}", d] }]
          end

    sub_types.each do |type, dir|
      desc "Run the code examples in #{dir}"
      RSpec::Core::RakeTask.new(type => "spec:prepare") do |t|
        t.pattern = "./#{dir}/**/*_spec.rb"
      end
    end

    # custom task to brake down feature/work_packages specs
    desc "Run specs features/work_packages without inplace editor specs"
    RSpec::Core::RakeTask.new('features:work_packages:wo_inplace' => 'spec:prepare') do |t|
      t.pattern = 'spec/features/work_packages/**/*_spec.rb'
      t.exclude_pattern = 'spec/features/work_packages/inplace_editor/**/*_spec.rb'
    end

    # custom task to brake down feature/work_packages specs
    desc "Run specs features/work_packages inplace editor specs"
    RSpec::Core::RakeTask.new('features:work_packages:inplace' => 'spec:prepare') do |t|
      t.pattern = 'spec/features/work_packages/inplace_editor/**/*_spec.rb'
    end

  rescue LoadError
    # when you bundle without development and test (e.g. to create a deployment
    # artefact) still all tasks get loaded. To avoid an error we rescue here.
  end
end

%w(spec).each do |type|
  if Rake::Task.task_defined?("#{type}:prepare")
    # FIXME: only webpack for feature specs
    Rake::Task["#{type}:prepare"].enhance(['assets:webpack'])
  end
end
