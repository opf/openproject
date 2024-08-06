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

module Members
  class RowComponent < ::RowComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
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
      return unless may_view_shared_work_packages?
      return if member.shared_work_package_ids.empty?

      shared_work_packages_link
    end

    def shared_work_packages_count = member.shared_work_package_ids.length

    def shared_work_packages_link
      link_to I18n.t(:label_x_work_packages, count: shared_work_packages_count),
              shared_work_packages_url,
              target: "_blank",
              rel: "noopener"
    end

    def shared_work_packages_url
      if member.other_shared_work_packages_count.zero?
        all_shared_work_packages_url
      else
        helpers.project_work_packages_with_ids_path(member.shared_work_package_ids, member.project)
      end
    end

    delegate :all_shared_work_packages_count, to: :member

    def all_shared_work_packages_link
      link_to I18n.t(:label_x_work_packages, count: all_shared_work_packages_count),
              all_shared_work_packages_url,
              target: "_blank",
              rel: "noopener"
    end

    def all_shared_work_packages_url
      helpers.project_work_packages_shared_with_path(principal, member.project)
    end

    def administration_settings_link
      link_to "administration settings",
              edit_user_path(model.principal, tab: :groups),
              target: "_blank",
              rel: "noopener"
    end

    def roles_label
      project_roles = member.roles.grep(ProjectRole).uniq.sort
      label = h project_roles.collect(&:name).join(", ")

      if principal&.admin?
        label << tag(:br) if project_roles.any?
        label << I18n.t(:label_member_all_admin)
      end

      label
    end

    def role_form
      render Members::RoleFormComponent.new(
        member.project_role? ? member : Member.new(project:, principal:),
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

    def shared_work_packages? = member.shared_work_package_ids.present?

    def may_update? = table.authorize_update
    def may_delete? = table.authorize_delete
    def may_view_shared_work_packages? = table.authorize_work_package_shares_view
    def may_delete_shares? = table.authorize_work_package_shares_delete
    def may_manage_user? = table.authorize_manage_user

    def can_update? = may_update? && !table.hide_roles?
    def can_delete? = may_delete? && member.project_role? && member.deletable?
    def can_delete_roles? = may_delete? && member.project_role? && member.some_roles_deletable?
    def can_view_shared_work_packages? = may_view_shared_work_packages? && shared_work_packages?

    def button_links
      return [] if actions.empty?

      if actions.one?
        actions.first => {label:, **button_options}

        [render(Primer::Beta::IconButton.new(**button_options, size: :small, "aria-label": label))]
      else
        [
          render(Primer::Alpha::ActionMenu.new) do |menu|
            menu.with_show_button(scheme: :invisible, size: :small, icon: :"kebab-horizontal", "aria-label": t(:button_actions),
                                  tooltip_direction: :w)
            actions.each do |action_options|
              action_options => {scheme:, label:, icon:, **button_options}
              menu.with_item(scheme:, label:, content_arguments: button_options) do |item|
                item.with_leading_visual_icon(icon:)
              end
            end
          end
        ]
      end
    end

    def actions
      @actions ||= [].tap do |actions|
        actions << edit_action_options if can_update?
        actions << view_work_package_shares_action_options if can_view_shared_work_packages?
        actions << delete_action_options if may_delete? && member.project_role?
        actions << delete_work_package_shares_action_options if may_delete_shares? && shared_work_packages?
      end
    end

    def edit_action_options
      {
        scheme: :default,
        icon: :pencil,
        label: I18n.t(:button_manage_roles),
        data: {
          action: "members-form#toggleMembershipEdit",
          members_form_toggling_class_param: toggle_item_class_name
        }
      }
    end

    def delete_action_options
      dialog = Members::DeleteMemberDialogComponent.new(member, row: self)

      content_for :content_body do
        render(dialog)
      end

      {
        scheme: :danger,
        icon: "op-person-remove",
        label: I18n.t(:button_remove_member),
        data: {
          show_dialog_id: dialog.id
        }
      }
    end

    def view_work_package_shares_action_options
      {
        scheme: :default,
        tag: :a,
        icon: "op-view-list",
        label: I18n.t(:button_view_shared_work_packages),
        href: shared_work_packages_url
      }
    end

    def delete_work_package_shares_action_options
      dialog = Members::DeleteWorkPackageSharesDialogComponent.new(member, row: self)

      content_for :content_body do
        render(dialog)
      end

      {
        scheme: :danger,
        icon: :trash,
        label: I18n.t(:button_revoke_work_package_shares),
        data: {
          show_dialog_id: dialog.id
        }
      }
    end

    def roles_css_id
      "member-#{member.id}-roles"
    end

    def toggle_item_class_name
      "member-#{member.id}--edit-toggle-item"
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
