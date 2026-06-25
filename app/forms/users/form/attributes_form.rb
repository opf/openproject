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
    # Admin flag + the custom-field sections (built-in fields interleaved with
    # custom fields per UserCustomFieldSection, honoring attribute_order).
    class AttributesForm < ApplicationForm
      include CustomFields::CustomFieldRendering

      form do |f|
        account_section(f)
        user_sections(f)
      end

      def initialize(user:, contract:)
        super()
        @user = user
        @contract = contract
      end

      private

      def custom_fields
        @custom_fields ||= @user.available_custom_fields
      end

      # Built-in account attributes grouped under their own section so they read
      # as account settings rather than as part of the avatar block rendered
      # above the form. For persisted users the current status is shown as a
      # read-only line at the top of the section.
      def account_section(form)
        return unless show_account_section?

        form.fieldset_group(title: I18n.t(:label_account)) do |group|
          account_status(group) if @user.persisted?
          admin_flag(group) if User.current.admin?
        end
      end

      def show_account_section?
        @user.persisted? || User.current.admin?
      end

      # The current status (e.g. active, locked) as a read-only line rather than
      # folded into the section title.
      def account_status(group)
        status = "#{User.human_attribute_name(:status)}: #{helpers.full_user_status(@user, true)}"
        group.html_content do
          render(Primer::Beta::Text.new(tag: :p)) { status }
        end
      end

      def admin_flag(group)
        group.check_box(name: :admin,
                        label: User.human_attribute_name(:admin),
                        disabled: @user == User.current)
      end

      def user_sections(form)
        UserCustomFieldSection.includes(:custom_fields).each do |section| # rubocop:disable Rails/FindEach -- honor default scope ordering
          render_section(form, section)
        end
      end

      def render_section(form, section)
        visible_cfs_by_key = section.custom_fields.visible(User.current).index_by(&:column_name)

        form.fieldset_group(title: section_title(section), mb: 3) do |group|
          section.attribute_order.each do |key|
            if UserCustomFieldSection::BUILT_IN_ATTRIBUTES.include?(key)
              render_built_in(group, key)
            elsif (custom_field = visible_cfs_by_key[key])
              render_custom_field(form: group, custom_field:)
            end
          end
        end
      end

      def section_title(section)
        section.name.presence || I18n.t("settings.user_custom_fields.label_untitled_section")
      end

      def render_built_in(group, key)
        case key
        when "firstname", "lastname", "mail"
          group.text_field(name: key.to_sym,
                           label: User.human_attribute_name(key),
                           required: true,
                           input_width: :medium,
                           **editability(key))
        when "login"
          return if @user.new_record?

          group.text_field(name: :login,
                           label: User.human_attribute_name(:login),
                           required: true,
                           input_width: :medium,
                           **editability(:login))
        when "language"
          render_language(group)
        when "department"
          render_department(group)
        end
      end

      def render_language(group)
        group.select_list(name: :language,
                          label: User.human_attribute_name(:language),
                          include_blank: "--- #{I18n.t(:actionview_instancetag_blank_option)} ---",
                          input_width: :medium) do |list|
          helpers.lang_options_for_select.each { |label, value| list.option(label:, value:) }
        end
      end

      # A user belongs to at most one department (an organizational unit group).
      # The field is editable by administrators only and disabled when the current
      # department is managed by LDAP, since LDAP owns that membership.
      def render_department(group)
        group.select_list(name: :department_id,
                          label: User.human_attribute_name(:department),
                          include_blank: "--- #{I18n.t(:actionview_instancetag_blank_option)} ---",
                          input_width: :medium,
                          **department_editability) do |list|
          department_options.each do |department|
            prefix = "  " * (department.hierarchy_depth || 0)
            # LDAP-managed departments own their membership; assigning into them
            # would fail validation, so they cannot be chosen as a target.
            list.option(label: "#{prefix}#{department.name}",
                        value: department.id,
                        selected: @user.department&.id == department.id,
                        disabled: department.ldap_managed?)
          end
        end
      end

      def department_options
        @department_options ||= Group.organizational_units.in_tree_order
      end

      def department_editable?
        User.current.active_admin? && !@user.department&.ldap_managed?
      end

      def department_editability
        return {} if department_editable?

        options = { disabled: true }
        options[:caption] = I18n.t("user.department_ldap_managed_caption") if @user.department&.ldap_managed?
        options
      end

      # Editability options for a built-in text field. Administration disables
      # non-writable attributes; self-service overrides this to render them
      # read-only with an explanatory caption instead.
      def editability(key)
        { disabled: !@contract.writable?(key.to_sym) }
      end
    end
  end
end
