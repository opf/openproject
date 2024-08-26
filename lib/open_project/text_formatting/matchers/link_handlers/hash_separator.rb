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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class HashSeparator < Base
      def self.allowed_prefixes
        %w(version message project user group document meeting view)
      end

      ##
      # Hash-separated object links
      # Condition: Separator is '#'
      # Condition: Prefix is present, checked to be one of the allowed values
      def applicable?
        matcher.sep == "#" && valid_prefix? && oid.present?
      end

      # Examples:
      #     document#17 -> Link to document with id 17
      #     version#3 -> Link to version with id 3
      #     message#1218 -> Link to message with id 1218
      #
      def call
        send :"render_#{matcher.prefix}"
      end

      def valid_prefix?
        allowed_prefixes.include?(matcher.prefix)
      end

      private

      def render_version
        version = Version.find_by(id: oid)
        if version
          link_to h(version.name),
                  { only_path: context[:only_path], controller: "/versions", action: "show", id: version },
                  class: "version"
        end
      end

      def render_document
        if document = Document.visible.find_by_id(oid)
          link_to document.title,
                  { only_path: context[:only_path],
                    controller: "/documents",
                    action: "show",
                    id: document },
                  class: "document"
        end
      end

      def render_meeting
        meeting = Meeting.find_by_id(oid)
        if meeting&.visible?(User.current)
          link_to meeting.title,
                  { only_path: context[:only_path],
                    controller: "/meetings",
                    action: "show",
                    id: oid },
                  class: "meeting"
        end
      end

      def render_message
        message = Message.includes(:parent).find_by(id: oid)
        if message
          link_to_message(message, { only_path: context[:only_path] }, class: "message")
        end
      end

      def render_project
        p = Project.find_by(id: oid)
        if p
          link_to_project(p, { only_path: context[:only_path] }, class: "project")
        end
      end

      def render_user
        user = User.find_by(id: oid)
        if user
          link_to_user(user,
                       only_path: context[:only_path],
                       class: "user-mention")
        end
      end

      def render_group
        group = Group.find_by(id: oid)

        if group
          link_to_group(group,
                        only_path: context[:only_path],
                        class: "user-mention")
        end
      end

      # view is the user-facing name of work package queries
      # query is the technical/internal name of the concept
      def render_view
        query = Query.find_by(id: oid)

        if query
          link_to_query(query,
                        { only_path: context[:only_path] },
                        class: "query")
        end
      end
    end
  end
end
