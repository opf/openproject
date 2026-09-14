# frozen_string_literal: true

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

module Admin
  module Members
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :member, :model

      delegate :principal, to: :member

      def row_css_id
        "member-#{member.id}"
      end

      def user
        render(Users::AvatarComponent.new(user: principal, size: :mini, link: true, show_name: true))
      end

      def project
        return global_membership_label if member.project.nil?

        # Archived projects have no reachable page, so this renders their name as plain text.
        content_tag(:span, helpers.link_to_project(member.project),
                    data: { "test-selector": "op-admin-members--project" })
      end

      def roles
        return role_list if inherited_via.empty?

        render(Primer::Box.new(display: :flex, align_items: :center, flex_wrap: :wrap, classes: "gap-1")) do
          safe_join([role_list, inheritance_note])
        end
      end

      private

      def role_list
        content_tag(:span, safe_join(role_links, ", "),
                    data: { "test-selector": "op-admin-members--roles" })
      end

      def inheritance_note
        render(Primer::Beta::Text.new(color: :muted,
                                      font_size: :small,
                                      test_selector: "op-admin-members--inherited")) do
          I18n.t("admin.members.index.inherited_via", source: inherited_via.to_sentence)
        end
      end

      def inherited_via
        @inherited_via ||= member
                              .member_roles
                              .filter_map { table.inheritance_sources[it.inherited_from] }
                              .uniq
                              .sort_by(&:name)
                              .map { source_label(it) }
      end

      def source_label(source)
        I18n.t("admin.members.index.inheritance_source", type: source.model_name.human, name: source.name)
      end

      def role_links
        member.roles.sort_by(&:name).map do |role|
          render(Primer::Beta::Link.new(href: edit_role_path(role), underline: false)) { role.name }
        end
      end

      def global_membership_label
        render(Primer::Beta::Text.new(color: :subtle, font_style: :italic)) { I18n.t(:label_global) }
      end
    end
  end
end
