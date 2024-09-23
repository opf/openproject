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

namespace :git do
  desc "Clean up your locale and remote repository"
  task :clean do
    # FIXME: change this to master once we are there
    main_branch       = "dev"
    excluded_branches = [
      main_branch,
      "release/4.0",
      "release/4.1",
      "release/4.2"
    ].join("|")

    # symbolic-ref gives us sth. like "refs/heads/foo" and we just need 'foo'
    current_branch = `git symbolic-ref HEAD`.chomp.split("/").last

    # we don't want to remove the current branch
    excluded_branches << current_branch

    if current_branch != main_branch
      if $CHILD_STATUS.exitstatus == 0
        puts "WARNING: You are on branch #{current_branch}, NOT #{main_branch}."
      else
        puts "WARNING: You are not on a branch"
      end
      puts
    end

    puts "Updating to most current code from origin ..."
    `git fetch origin`

    puts "Pruning remote origin ..."
    `git remote prune origin`

    puts "Fetching merged branches..."
    remote_branches = `git branch -r --merged`
                      .split("\n")
                      .map(&:strip)
                      .reject do |b|
                        !b.starts_with?("origin") ||
                          excluded_branches.include?(b.split("/").drop(1).join("/"))
                      end

    local_branches = `git branch --merged`
                     .gsub(/^\* /, "")
                     .split("\n")
                     .map(&:strip)
                     .reject { |b| excluded_branches.include?(b) }

    if remote_branches.empty? && local_branches.empty?
      puts "No existing branches have been merged into #{current_branch}."
    else
      puts "This will remove the following branches:"
      puts remote_branches.join("\n")
      puts local_branches.join("\n")
      puts "Proceed? (y/n)"

      if /^y/i.match?(STDIN.gets)
        remote_branches.each do |b|
          match = b.match(/^([^\/]+)\/(.+)/)
          remote = match[1]
          branch = match[2]

          `git push #{remote} :#{branch}`
        end

        # Remove local branches
        `git branch -d #{local_branches.join(" ")}`
      else
        puts "No branches removed."
      end
    end
  end
end
