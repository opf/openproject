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

module OpenProject::GithubIntegration
  module NotificationHandler
    module Helper
      ##
      # Parses the given `text` and returns a list of work_package ids mentioned in that text.
      def extract_work_package_ids(text)
        # matches the following things (given that `Setting.host_name` equals 'www.openproject.org')
        #  - http://www.openproject.org/wp/1234
        #  - https://www.openproject.org/wp/1234
        #  - http://www.openproject.org/work_packages/1234
        #  - https://www.openproject.org/subdirectory/work_packages/1234
        # Or with the following prefix: OP#
        # e.g.,: This is a reference to OP#1234
        host_name = Regexp.escape(Setting.host_name)
        wp_regex = /OP#(\d+)|http(?:s?):\/\/#{host_name}\/(?:\S+?\/)*(?:work_packages|wp)\/([0-9]+)/

        text.scan(wp_regex)
          .map { |first, second| (first || second).to_i }
          .select(&:positive?)
          .uniq
      end

      ##
      # Given a list of work package ids, this methods returns all work packages that match those ids
      # and are visible by the given user.
      # Params:
      #  - Array<int>: An list of WorkPackage ids
      #  - User: The user who may (or may not) see those WorkPackages
      # Returns:
      #  - Array<WorkPackage>
      def find_visible_work_packages(ids, user)
        WorkPackage.includes(:project)
                  .where(id: ids)
                  .select { |wp| user.allowed_to?(:add_work_package_notes, wp.project) }
      end

      # Returns a list of `WorkPackage`s that were referenced in the `text` and are visible to the given `user`.
      def find_mentioned_work_packages(text, user)
        find_visible_work_packages(extract_work_package_ids(text), user)
      end

      ##
      # Adds comments to the given WorkPackages.
      def comment_on_referenced_work_packages(work_packages, user, notes)
        return if notes.nil?

        work_packages.each do |work_package|
          ::WorkPackages::UpdateService
            .new(user: user, model: work_package)
            .call(journal_notes: notes, send_notifications: false)
        end
      end
    end
  end
end
