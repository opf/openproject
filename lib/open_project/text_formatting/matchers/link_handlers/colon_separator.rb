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
    class ColonSeparator < Base
      def self.allowed_prefixes
        %w(commit source export version project user attachment document meeting view)
      end

      ##
      # Colon-separated object links
      # Condition: Separator is ':'
      # Condition: Prefix is present, checked to be one of the allowed values
      def applicable?
        matcher.sep == ":" && valid_prefix? && oid.present?
      end

      #   Documents:
      #     document:Greetings -> Link to the document with title "Greetings"
      #     document:"Some document" -> Link to the document with title "Some document"
      #   Versions:
      #     version:1.0.0 -> Link to version named "1.0.0"
      #     version:"1.0 beta 2" -> Link to version named "1.0 beta 2"
      #   Attachments:
      #     attachment:file.zip -> Link to the attachment of the current object named file.zip
      #   Source files:
      #     source:"some/file" -> Link to the file located at /some/file in the project's repository
      #     source:"some/file@52" -> Link to the file's revision 52
      #     source:"some/file#L120" -> Link to line 120 of the file
      #     source:"some/file@52#L120" -> Link to line 120 of the file's revision 52
      #     export:"some/file" -> Force the download of the file
      #
      #   Links can refer other objects from other projects, using project identifier:
      #     identifier:r52
      #     identifier:document:"Some document"
      #     identifier:version:1.0.0
      #     identifier:source:some/file
      def call
        send prefix_method
      end

      def valid_prefix?
        allowed_prefixes.include?(matcher.prefix)
      end

      def prefix_method
        "render_#{matcher.prefix}"
      end

      def oid
        matcher.identifier&.gsub(%r{\A"(.*)"\z}, '\\1')
      end

      private

      def render_version
        if project && (version = project.versions.find_by(name: oid))
          link_to h(version.name),
                  { only_path: context[:only_path], controller: "/versions", action: "show", id: version },
                  class: "version"
        end
      end

      def render_commit
        if project&.repository &&
           (changeset = Changeset.where(["repository_id = ? AND scmid LIKE ?", project.repository.id, "#{oid}%"]).first)
          link_to h("#{matcher.project_prefix}#{matcher.identifier}"),
                  { only_path: context[:only_path], controller: "/repositories", action: "revision", project_id: project,
                    rev: changeset.identifier },
                  class: "changeset",
                  title: truncate_single_line(changeset.comments, length: 100)
        end
      end

      def render_source
        if project&.repository
          matcher.identifier =~ %r{\A[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?\z}
          path = $1
          rev = $3
          anchor = $5
          link_to h("#{matcher.project_prefix}#{matcher.prefix}:#{oid}"),
                  named_route(:entry_revision_project_repository,
                              action: "entry",
                              project_id: project.identifier,
                              repo_path: path.to_s,
                              rev:,
                              anchor:,
                              format: (matcher.prefix == "export" ? "raw" : nil)),
                  class: (matcher.prefix == "export" ? "source download" : "source")
        end
      end
      alias :render_export :render_source

      def render_attachment
        attachments = context[:attachments] || context[:object].try(:attachments)
        if attachments && attachment = attachments.detect { |a| a.filename == oid }
          link_to h(attachment.filename),
                  { only_path: context[:only_path], controller: "/attachments", action: "download", id: attachment },
                  class: "attachment"
        end
      end

      def render_project
        p = Project
            .where(["projects.identifier = :s OR LOWER(projects.name) = :s", { s: oid.downcase }])
            .first
        if p
          link_to_project(p, { only_path: context[:only_path] }, class: "project")
        end
      end

      def render_user
        if (user = User.find_by(login: oid))
          link_to_user(user, only_path: context[:only_path], class: "user-mention")
        end
      end

      def render_document
        scope = project ? project.documents : Document
        document = scope
          .visible
          .where(["LOWER(title) = :s", { s: oid.downcase }])
          .first

        if document
          link_to document.title,
                  { only_path: context[:only_path],
                    controller: "/documents",
                    action: "show",
                    id: document.id },
                  class: "document"
        end
      end

      def render_meeting
        scope = project ? project.meetings : Meeting
        meeting = scope
          .where(["LOWER(title) = :s", { s: oid.downcase }])
          .first

        if meeting && meeting.visible?(User.current)
          link_to meeting.title,
                  { only_path: context[:only_path], controller: "/meetings", action: "show", id: meeting.id },
                  class: "meeting"
        end
      end

      # view is the user-facing name of work package queries
      # query is the technical/internal name of the concept
      def render_view
        if oid == "default"
          link_to "Work packages",
                  { controller: "work_packages", action: "index", project_id: project.id },
                  class: "query"
        end
      end
    end
  end
end
