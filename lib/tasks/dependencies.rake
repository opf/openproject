#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'open3'

namespace :openproject do
  namespace :dependencies do
    desc 'Updates everything that is updatable automatically especially dependencies'
    task update: ['openproject:dependencies:update:gems',
                  'openproject:dependencies:update:rubocop']

    namespace :update do
      def parse_capture(capture, &block)
        capture
          .split("\n")
          .map do |line|
          block.call(line)
        end.compact
      end


      desc 'Update gems to the extend the Gemfile allows in individual commits'
      task :gems do
        out, _process = Open3.capture3('bundle', 'outdated', '--parseable')

        parsed = parse_capture(out) do |line|
          line.match(/(\S+) \(newest ([0-9.]+), installed ([0-9.]+)(?:, requested .{0,2} ([0-9.]+))?\)/).to_a[1..4]
        end

        parsed.map(&:first).each do |gem|
          puts "Updating #{gem}"
          _out, error = Open3.capture3('bundle', 'update', gem)

          if error.present?
            puts "Attempted to update #{gem} but failed: #{error}"
          else
            out, _process = Open3.capture3('git', 'diff', 'Gemfile.lock')

            parsed = parse_capture(out) do |line|
              line.match(/\A\+\s{4}(\S+) \(([0-9.]+)\)\z/).to_a[1..2]
            end

            parsed.each do |gem, version|
              puts "  #{gem}: #{version}"
            end

            Open3.capture3('git', 'add', 'Gemfile.lock')
            Open3.capture3('git', 'commit', '-m', "bump #{parsed.map(&:first).join(' & ')}")
          end
        end
      end

      desc 'Update rubocop used on codeclimate to the extend supported'
      task :rubocop do
        out, _process = Open3.capture3('git',
                                       'ls-remote',
                                       'https://github.com/codeclimate/codeclimate-rubocop',
                                       'channel/rubocop*')

        parsed = parse_capture(out) do |line|
          matches = line.match(/rubocop-(\d+)-(\d+)(?:-(\d+))?/).to_a

          # This version seems to have been a mistake
          next if matches[0] == 'rubocop-1-70'

          matches[1..3].map(&:to_i) + [matches[0]]
        end

        new_version = parsed.sort.pop.last

        Open3.capture3('sed', '-i.bak', "s/channel: rubocop[-0-9]*/channel: #{new_version}/", '.codeclimate.yml')
        Open3.capture3('rm', '.codeclimate.yml.bak')
        Open3.capture3('git', 'add', '.codeclimate.yml')
        Open3.capture3('git', 'commit', '-m', "use #{new_version} on codeclimate")
      end
    end
  end
end
