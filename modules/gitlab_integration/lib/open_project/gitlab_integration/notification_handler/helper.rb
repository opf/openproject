#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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

module OpenProject::GitlabIntegration
  module NotificationHandler
    module Helper
      ##
      # Parses the given source string and returns a list of work package display identifiers
      # (numeric strings or semantic IDs like "PROJ-42") found in that text.
      # WorkPackages are identified by their URL or by an OP#/PP# prefix.
      # Params:
      #  source: string
      #  kind: "" (default) | "note" | "private"
      # Returns:
      #   Array<String>
      def extract_work_package_ids(text, kind = "")
        # matches the following things (given that `Setting.host_name` equals 'www.openproject.org')
        #  - http://www.openproject.org/wp/1234
        #  - https://www.openproject.org/wp/1234
        #  - http://www.openproject.org/work_packages/1234
        #  - https://www.openproject.org/subdirectory/work_packages/1234
        # Or with the following prefix: OP# PP#
        # e.g.,: This is a reference to OP#1234 or OP#PROJ-42
        # For private comments you can use the prefix: PP#
        host_name = Regexp.escape(Setting.host_name)
        wp_id     = WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT
        url_part  = /http(?:s?):\/\/#{host_name}\/(?:\S+?\/)*(?:work_packages|wp)\/(#{wp_id})/

        wp_regex = case kind
                   when "private"
                     /PP#(#{wp_id})/
                   when "note"
                     /OP#(#{wp_id})|#{url_part}/
                   else
                     /OP#(#{wp_id})|PP#(#{wp_id})|#{url_part}/
                   end

        String(text)
          .scan(wp_regex)
          .filter_map { |groups| groups.compact.first }
          .uniq
      end

      ##
      # Given a list of work package display identifiers this methods returns all work packages
      # that match those identifiers and are visible by the given user.
      # Params:
      #  - Array<String>: A list of WorkPackage display identifiers
      #  - User: The user who may (or may not) see those WorkPackages
      # Returns:
      #  - Array<WorkPackage>
      def find_visible_work_packages(ids, user)
        WorkPackage
          .includes(:project)
          .where_display_id_in(ids)
          .select { |wp| user.allowed_in_work_package?(:add_work_package_comments, wp) }
      end

      # Returns a list of `WorkPackage`s that were referenced in the `text` and are visible to the given `user`.
      def find_mentioned_work_packages(text, user, kind = "")
        find_visible_work_packages(extract_work_package_ids(text, kind), user)
      end

      # Returns a list of `WorkPackage`s that were excluded in the `text`.
      def find_excluded_work_packages(text, user)
        find_visible_work_packages(extract_work_package_ids(text, "private"), user)
      end

      ##
      # Adds comments to the given WorkPackages.
      def comment_on_referenced_work_packages(work_packages, user, notes)
        return if notes.nil?

        work_packages.each do |work_package|
          ::WorkPackages::UpdateService
            .new(user:, model: work_package)
            .call(journal_notes: notes, send_notifications: false)
        end
      end

      ##
      # Adds comments to the given WorkPackages.
      def status_on_referenced_work_packages(work_packages, user, status)
        work_packages.each do |work_package|
          ::WorkPackages::UpdateService
            .new(user:, model: work_package)
            .call(status_id: status)
        end
      end

      ##
      # A wapper around a ruby Hash to access webhook payloads.
      # All methods called on it are converted to `.fetch` hash-access, raising an error if the string-key does not exist.
      # If the method ends with a question mark, e.g. "comment?" not error is raised if the key does not exist.
      # If the fetched value is again a hash, the value is wrapped into a new payload object.
      class Payload
        def initialize(payload)
          @payload = payload
        end

        def to_h
          @payload.dup
        end

        def method_missing(name, *args, &block)
          super unless args.empty? && block.nil?

          value = if name.end_with?("?")
                    @payload.fetch(name.to_s[..-2], nil)
                  else
                    @payload.fetch(name.to_s)
                  end

          return Payload.new(value) if value.is_a?(Hash)

          value
        end

        def respond_to_missing?(_method_name, _include_private = false)
          true
        end
      end

      def wrap_payload(payload)
        Payload.new(payload)
      end
    end
  end
end
