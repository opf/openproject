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

module Users
  module Form
    # The "Authentication" fieldset: every authentication scheme for the user,
    # in one titled section. The coordinator decides which parts apply and only
    # includes this form when at least one does:
    # - external authentication (OmniAuth/OIDC): a read-only display of the
    #   provider and identity url -- mutually exclusive with everything below;
    # - the LDAP source select when LDAP sources can be assigned (and, for a new
    #   record, the hidden login the admin--users controller reveals once a
    #   source is selected);
    # - the internal password settings when editing an internal user as admin
    #   while password login is enabled (the controller toggles these against
    #   the source select);
    # - a notice that the user cannot log in when password login is disabled.
    class AuthenticationForm < ApplicationForm
      form do |f|
        f.fieldset_group(title: I18n.t(:label_authentication), mb: 3) do |group|
          if @render_external_auth
            external_authentication(group)
          else
            if @render_auth_source
              ldap_auth_source_select(group)
              hidden_login(group) if @user.new_record?
            end

            password_group(group) if @render_password
            no_login_message(group) if @render_no_login_message
          end
        end
      end

      def initialize(user:, render_auth_source:, render_password:, render_no_login_message:, render_external_auth:,
                     assign_random_password_checked: false)
        super()
        @user = user
        @render_auth_source = render_auth_source
        @render_password = render_password
        @render_no_login_message = render_no_login_message
        @render_external_auth = render_external_auth
        @assign_random_password_checked = assign_random_password_checked
      end

      private

      # The provider and identity url as a read-only block, shown for users that
      # authenticate through an external OmniAuth/OIDC provider.
      def external_authentication(group)
        group.html_content do
          render("users/form/authentication/external", user: @user)
        end
      end

      # The LDAP source select, with a blank "internal" option. Its admin--users
      # action toggles the password and LDAP groups as the selection changes.
      def ldap_auth_source_select(group)
        group.select_list(
          name: :ldap_auth_source_id,
          label: User.human_attribute_name(:auth_source),
          include_blank: I18n.t(:label_internal),
          input_width: :medium,
          data: { action: "admin--users#toggleAuthenticationFields" }
        ) do |list|
          LdapAuthSource.order(:name).each { |source| list.option(label: source.name, value: source.id) }
        end
      end

      # The login as a nested group, hidden by default. The admin--users controller
      # reveals it (its authSourceFields target) when an LDAP source is selected.
      def hidden_login(group)
        group.group(hidden: true, data: { "admin--users-target": "authSourceFields" }) do |login_group|
          login_group.text_field(name: :login,
                                 label: User.human_attribute_name(:login),
                                 required: true,
                                 input_width: :medium)
        end
      end

      # The password options as a nested group, visible by default. The admin--users controller
      # hides it (its passwordFields target) when an LDAP source is selected.
      def password_group(group)
        group.group(
          hidden: !@user.change_password_allowed?,
          data: {
            controller: "disable-when-checked password-force-change password-requirements",
            "admin--users-target": "passwordFields"
          }
        ) do |password_group|
          assign_random_password(password_group)
          password_fields(password_group) unless disable_password_choice?
          send_information(password_group)
          force_password_change(password_group)
        end
      end

      def disable_password_choice?
        OpenProject::Configuration.disable_password_choice?
      end

      def assign_random_password(group)
        group.check_box(name: :assign_random_password,
                        id: "user_assign_random_password",
                        checked: @assign_random_password_checked,
                        include_hidden: false,
                        label: I18n.t("user.assign_random_password"),
                        data: {
                          "disable-when-checked-target": "cause",
                          "password-force-change-target": "assignRandomPassword"
                        })
      end

      def password_fields(group)
        group.text_field(name: :password,
                         id: "user_password",
                         type: :password,
                         required: @user.new_record?,
                         label: User.human_attribute_name(:password),
                         caption: helpers.password_complexity_requirements,
                         input_width: :medium,
                         data: {
                           "disable-when-checked-target": "effect",
                           "password-requirements-target": "passwordInput"
                         })
        group.text_field(name: :password_confirmation,
                         id: "user_password_confirmation",
                         type: :password,
                         required: @user.new_record?,
                         label: User.human_attribute_name(:password_confirmation),
                         input_width: :medium,
                         data: { "disable-when-checked-target": "effect" })
      end

      def send_information(group)
        group.check_box(name: :send_information,
                        id: "send_information",
                        scope_name_to_model: false,
                        scope_id_to_model: false,
                        checked: false,
                        include_hidden: false,
                        label: I18n.t(:label_send_information),
                        caption: I18n.t("users.send_information_hint"),
                        data: { "password-force-change-target": "sendInformationCheckbox" })
      end

      def force_password_change(group)
        group.check_box(name: :force_password_change,
                        id: "user_force_password_change",
                        checked: @user.force_password_change,
                        label: User.human_attribute_name(:force_password_change),
                        caption: I18n.t("users.force_password_change_hint"),
                        data: { "password-force-change-target": "forceChangeCheckbox" })
      end

      # A warning that the user cannot log in, shown for an internal user when
      # password login is disabled instance-wide.
      def no_login_message(group)
        group.html_content do
          render(Primer::OpenProject::InlineMessage.new(scheme: :warning)) { I18n.t("user.no_login") }
        end
      end
    end
  end
end
