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

      def gemfile_lock_dirty?
        out, = Open3.capture3("git", "status", "--porcelain", "--", "Gemfile.lock")
        out.present?
      end

      desc "Update gems to the extend the Gemfile allows in individual commits"
      task :gems do
        abort "Gemfile.lock has uncommitted changes. Commit or stash them first." if gemfile_lock_dirty?

        out, = Open3.capture3("bundle", "outdated", "--parseable")

        gem_names = parse_capture(out) do |line|
          next unless (name = line[/\A(\S+) \(newest /, 1])
          next if line.include?("in cooldown for") && line.exclude?("newest out of cooldown")

          name
        end

        gem_names.each do |gem_name|
          puts "Updating #{gem_name}"
          _out, error, status = Open3.capture3("bundle", "update", "--conservative", gem_name)

          unless status.success?
            puts "Attempted to update #{gem_name} but failed: #{error}"
            next
          end

          out, = Open3.capture3("git", "diff", "--", "Gemfile.lock")

          bumped = parse_capture(out) do |line|
            line.match(/\A\+ {4}(\S+) \((\S+)\)\z/)&.captures
          end

          if bumped.empty?
            puts "  nothing changed"
            next
          end

          bumped.each do |name, version|
            puts "  #{name}: #{version}"
          end

          Open3.capture3("git", "add", "Gemfile.lock")
          Open3.capture3("git", "commit", "-m", "bump #{bumped.map(&:first).join(' & ')}")
        end
      end
    end
  end
end
