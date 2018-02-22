#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class ColonSeparator < Base

      ##
      # Colon-separated object links
      # Condition: Separator is ':'
      # Condition: Prefix is present, checked to be one of the allowed values
      def applicable?
        matcher.sep == ':' && valid_prefix? && oid.present?
      end

      # Examples:
      #     document#17 -> Link to document with id 17
      #     version#3 -> Link to version with id 3
      #     message#1218 -> Link to message with id 1218
      #
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
        if matcher.identifier
          matcher.identifier.gsub(%r{\A"(.*)"\z}, '\\1')
        end
      end

      private

      def allowed_prefixes
        %w(commit source export version message project user attachment)
      end

      def render_version
        if project && version = project.versions.visible.find_by(name: oid)
          link_to h(version.name),
                  { only_path: context[:only_path], controller: '/versions', action: 'show', id: version },
                  class: 'version'
        end
      end

      def render_commit
        if project && project.repository && (changeset = Changeset.visible.where(['repository_id = ? AND scmid LIKE ?', project.repository.id, "#{oid}%"]).first)
          link_to h("#{project_prefix}#{name}"),
                  { only_path: context[:only_path], controller: '/repositories', action: 'revision', project_id: project, rev: changeset.identifier },
                  class: 'changeset',
                  title: truncate_single_line(changeset.comments, length: 100)
        end
      end

      def render_source
        if project && project.repository && User.current.allowed_to?(:browse_repository, project)
          oid =~ %r{\A[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?\z}
          path = $1
          rev = $3
          anchor = $5
          link_to h("#{project_prefix}#{prefix}:#{oid}"),
                  { controller: '/repositories',
                    action: 'entry',
                    project_id: project,
                    path: path.to_s,
                    rev: rev,
                    anchor: anchor,
                    format: (prefix == 'export' ? 'raw' : nil)
                  },
                  class: (prefix == 'export' ? 'source download' : 'source')
        end
      end
      alias :render_export :render_source

      def render_attachment
        attachments = context[:attachments] || context[:object].try(:attachments)
        if attachments && attachment = attachments.detect { |a| a.filename == oid }
          link_to h(attachment.filename),
                  { only_path: context[:only_path], controller: '/attachments', action: 'download', id: attachment },
                  class: 'attachment'
        end
      end

      def render_project
        p = Project
          .visible
          .where(['projects.identifier = :s OR LOWER(projects.name) = :s', { s: oid.downcase }])
          .first
        if p
          link_to_project(p, { only_path: context[:only_path] }, class: 'project')
        end
      end

      def render_user
        if user = User.in_visible_project.find_by(login: oid)
          link_to_user(user, class: 'user-mention')
        end
      end
    end
  end
end
