#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "open3"

namespace :openproject do
  namespace :dependencies do
    desc "Updates everything that is updatable automatically especially dependencies"
    task update: %w[openproject:dependencies:update:gems]

    namespace :update do
      def parse_capture(capture, &)
        capture
          .split("\n")
          .filter_map(&)
      end

      desc "Update gems to the extend the Gemfile allows in individual commits"
      task :gems do
        out, _process = Open3.capture3("bundle", "outdated", "--parseable")

        parsed = parse_capture(out) do |line|
          line.match(/(\S+) \(newest ([0-9.]+), installed ([0-9.]+)(?:, requested .{0,2} ([0-9.]+))?\)/).to_a[1..4]
        end

        parsed.map(&:first).each do |gem|
          puts "Updating #{gem}"
          _out, error = Open3.capture3("bundle", "update", gem)

          if error.present?
            puts "Attempted to update #{gem} but failed: #{error}"
          else
            out, _process = Open3.capture3("git", "diff", "Gemfile.lock")

            parsed = parse_capture(out) do |line|
              line.match(/\A\+\s{4}(\S+) \(([0-9.]+)\)\z/).to_a[1..2]
            end

            parsed.each do |gem, version|
              puts "  #{gem}: #{version}"
            end

            Open3.capture3("git", "add", "Gemfile.lock")
            Open3.capture3("git", "commit", "-m", "bump #{parsed.map(&:first).join(' & ')}")
          end
        end
      end
    end
  end
end
