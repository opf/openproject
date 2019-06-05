#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

begin
  require 'spec/rake/spectask'
  namespace :spec do
    namespace :plugins do
      desc 'Runs the examples for reporting_engine'
      Spec::Rake::SpecTask.new(:reporting_engine) do |t|
        t.spec_opts = ['--options', "\"#{Rails.root}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/reporting_engine/spec/**/*_spec.rb']
      end

      desc 'Runs the examples for reporting_engine'
      Spec::Rake::SpecTask.new(:"reporting_engine:rcov") do |t|
        t.spec_opts = ['--options', "\"#{Rails.root}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/reporting_engine/spec/**/*_spec.rb']
        t.rcov = true
        t.rcov_opts = ['-x', "\.rb,spec", '-i', 'reporting_engine/app/,redmine_reporting/lib/']
      end
    end
  end
  task spec: 'spec:plugins:reporting_engine'

  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
  require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
  task :"spec:plugins:reporting_engine:ci" => ['ci:setup:rspec', 'spec:plugins:redmine_reporting']
rescue LoadError
end
