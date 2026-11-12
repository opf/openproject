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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CustomFields
    class RoleAssignmentPreviewDialogComponent < ApplicationComponent
      DIALOG_ID = "preview-role-assignment-dialog"

      MembershipChange = Struct.new(:user, :project, :change, keyword_init: true)

      include ApplicationHelper
      include OpenProject::FormTagHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :custom_field, :role

      def initialize(custom_field:, role:, **)
        @custom_field = custom_field
        @role = role
        super(**)
      end

      def call
        render(
          Primer::Alpha::Dialog.new(
            id: DIALOG_ID,
            title: I18n.t("custom_fields.admin.role_assignment.dialog.title"),
            size: :xlarge
          )
        ) do |dialog|
          dialog.with_header(variant: :large)
          dialog.with_body do
            render(RoleAssignment::PreviewTableComponent.new(rows: membership_changes))
          end

          dialog.with_footer do
            render(Primer::Beta::Button.new(data: { "close-dialog-id": DIALOG_ID })) { I18n.t(:button_close) }
          end
        end
      end

      private

      def membership_changes # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        custom_values = custom_field.custom_values.preload(:customized)
        user_ids = custom_values.filter_map(&:value)
        users = Principal.includes(:memberships).where(id: user_ids).index_by(&:id)

        custom_values.filter_map do |cv|
          user = users[cv.value.to_i]
          next if user.nil?

          membership = user.memberships.find { |m| m.project = cv.customized }

          change = if membership.nil?
                     if role.present?
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.new_member")
                     else
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.no_change")
                     end
                   else
                     roles_after = membership.roles - [custom_field.role].compact + [role].compact

                     if roles_after.empty?
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.remove_member")
                     elsif custom_field.role.present? && role.present?
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.gain_and_lose_role",
                              old_role: custom_field.role.name,
                              new_role: role.name)
                     elsif custom_field.role.nil? && role.present?
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.gain_role",
                              new_role: role.name)
                     elsif custom_field.role.present? && role.nil?
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.lose_role",
                              old_role: custom_field.role.name)
                     else
                       I18n.t("custom_fields.admin.role_assignment.dialog.changes.no_change")
                     end

                   end

          MembershipChange.new(
            user: user,
            project: cv.customized,
            change: change
          )
        end
      end
    end
  end
end
