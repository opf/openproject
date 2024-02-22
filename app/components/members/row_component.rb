# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Members
  class RowComponent < ::RowComponent
    property :principal
    delegate :project, to: :table

    def member
      model
    end

    def row_css_id
      "member-#{member.id}"
    end

    def row_css_class
      "member #{principal_class_name} principal-#{principal.id}".strip
    end

    def name
      render Users::AvatarComponent.new(user: principal, size: :mini, link: true, show_name: true)
    end

    def mail
      return unless user?
      return if principal.pref.hide_mail

      link = mail_to(principal.mail)

      if member.principal.invited?
        i = content_tag "i", "", title: t("text_user_invited"), class: "icon icon-mail1"

        link + i
      else
        link
      end
    end

    def roles
      span = content_tag "span", roles_label, id: "member-#{member.id}-roles"

      if may_update?
        span + role_form
      else
        span
      end
    end

    def shared
      count = member.shared_work_packages_count
      if count > 0
        link_to I18n.t(:label_x_work_packages, count:),
                helpers.project_work_packages_shared_with_path(principal, member.project),
                target: "_blank", rel: "noopener"
      end
    end

    def roles_label
      project_roles = member.roles.select { |role| role.is_a?(ProjectRole) }.uniq.sort
      label = h project_roles.collect(&:name).join(', ')

      if principal&.admin?
        label << tag(:br) if project_roles.any?
        label << I18n.t(:label_member_all_admin)
      end

      label
    end

    def role_form
      render Members::RoleFormComponent.new(
        member,
        row: self,
        params: controller.params,
        roles: table.available_roles
      )
    end

    def groups
      if user?
        (principal.groups & project.groups).map(&:name).join(", ")
      end
    end

    def status
      helpers.translate_user_status(model.principal.status)
    end

    def may_update?
      table.authorize_update
    end

    def may_delete?
      table.authorize_update
    end

    def button_links
      if !model.project_role?
        [share_warning]
      elsif may_update? && may_delete?
        [edit_link, delete_link].compact
      elsif may_delete?
        [delete_link].compact
      else
        []
      end
    end

    def share_warning
      content_tag(:span,
                  title: I18n.t('members.no_modify_on_shared')) do
        helpers.op_icon('icon icon-info1')
      end
    end

    def edit_link
      link_to(
        helpers.op_icon('icon icon-edit'),
        '#',
        class: "toggle-membership-button #{toggle_item_class_name}",
        'data-action': 'members-form#toggleMembershipEdit',
        'data-members-form-toggling-class-param': toggle_item_class_name,
        title: t(:button_edit)
      )
    end

    def roles_css_id
      "member-#{member.id}-roles"
    end

    def toggle_item_class_name
      "member-#{member.id}--edit-toggle-item"
    end

    def delete_link
      if model.deletable?
        link_to(
          helpers.op_icon('icon icon-delete'),
          { controller: '/members', action: 'destroy', id: model, page: params[:page] },
          method: :delete,
          data: { confirm: delete_link_confirmation, disable_with: I18n.t(:label_loading) },
          title: delete_title
        )
      end
    end

    def delete_title
      if model.disposable?
        I18n.t(:title_remove_and_delete_user)
      else
        I18n.t(:button_remove)
      end
    end

    def delete_link_confirmation
      if !User.current.admin? && model.include?(User.current)
        t(:text_own_membership_delete_confirmation)
      end
    end

    def column_css_class(column)
      if column == :mail
        "email"
      else
        super
      end
    end

    def principal_link
      link_to principal.name, principal_show_path
    end

    def principal_class_name
      principal.model_name.singular
    end

    def principal_show_path
      case principal
      when User
        user_path(principal)
      when Group
        show_group_path(principal)
      else
        placeholder_user_path(principal)
      end
    end

    def user?
      principal.is_a?(User)
    end
  end
end
