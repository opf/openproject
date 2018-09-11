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
    class HashSeparator < Base

      def self.allowed_prefixes
        %w(version message project user group)
      end

      ##
      # Hash-separated object links
      # Condition: Separator is '#'
      # Condition: Prefix is present, checked to be one of the allowed values
      def applicable?
        matcher.sep == '#' && valid_prefix? && oid.present?
      end

      # Examples:
      #     document#17 -> Link to document with id 17
      #     version#3 -> Link to version with id 3
      #     message#1218 -> Link to message with id 1218
      #
      def call
        send "render_#{matcher.prefix}"
      end

      def valid_prefix?
        allowed_prefixes.include?(matcher.prefix)
      end

      private

      def render_version
        version = Version.visible.find_by(id: oid)
        if version
          link_to h(version.name),
                  { only_path: context[:only_path], controller: '/versions', action: 'show', id: version },
                  class: 'version'
        end
      end

      def render_message
        message = Message.visible.includes(:parent).find_by(id: oid)
        if message
          link_to_message(message, { only_path: context[:only_path] }, class: 'message')
        end
      end

      def render_project
        p = Project.visible.find_by(id: oid)
        if p
          link_to_project(p, { only_path: context[:only_path] }, class: 'project')
        end
      end

      def render_user
        user = User.in_visible_project.find_by(id: oid)
        if user
          link_to_user(user, only_path: context[:only_path], class: 'user-mention')
        end
      end

      def render_group
        if group = Group.find_by(id: oid)
          content_tag :span,
                      group.name,
                      title: I18n.t(:label_group_named, name: group.name),
                      class: 'user-mention'
        end
      end
    end
  end
end
