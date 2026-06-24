# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class Form < ApplicationForm
      form do |tree_form|
        tree_form.text_field(
          name: :name,
          label: SynchronizedTree.human_attribute_name(:name),
          required: true,
          input_width: :large
        )

        tree_form.fieldset_group(title: I18n.t("ldap_departments.synchronized_trees.form.sections.connection"), mt: 1) do |group|
          group.select_list(
            name: :ldap_auth_source_id,
            label: SynchronizedTree.human_attribute_name(:ldap_auth_source),
            caption: I18n.t("ldap_departments.synchronized_trees.form.auth_source_text"),
            required: true,
            include_blank: true,
            input_width: :large
          ) do |list|
            LdapAuthSource.order(:name).pluck(:name, :id).each do |name, id|
              list.option(label: name, value: id)
            end
          end

          group.text_field(
            name: :base_dn,
            label: SynchronizedTree.human_attribute_name(:base_dn),
            required: true,
            caption: I18n.t("ldap_departments.synchronized_trees.form.base_dn_text"),
            input_width: :large
          )
        end

        tree_form.fieldset_group(title: I18n.t("ldap_departments.synchronized_trees.form.sections.structure"), mt: 1) do |group|
          group.text_field(
            name: :structure_filter_string,
            label: SynchronizedTree.human_attribute_name(:structure_filter_string),
            required: true,
            caption: I18n.t("ldap_departments.synchronized_trees.form.structure_filter_string_text"),
            input_width: :large
          )

          group.text_field(
            name: :ou_name_attribute,
            label: SynchronizedTree.human_attribute_name(:ou_name_attribute),
            required: true,
            caption: I18n.t("ldap_departments.synchronized_trees.form.ou_name_attribute_text"),
            input_width: :medium
          )

          group.text_field(
            name: :guid_attribute,
            label: SynchronizedTree.human_attribute_name(:guid_attribute),
            caption: I18n.t("ldap_departments.synchronized_trees.form.guid_attribute_text"),
            input_width: :medium
          )
        end

        tree_form.fieldset_group(title: I18n.t("ldap_departments.synchronized_trees.form.sections.users"), mt: 1) do |group|
          group.text_field(
            name: :user_filter_string,
            label: SynchronizedTree.human_attribute_name(:user_filter_string),
            caption: I18n.t("ldap_departments.synchronized_trees.form.user_filter_string_text"),
            input_width: :large
          )

          group.check_box(
            name: :sync_users,
            label: SynchronizedTree.human_attribute_name(:sync_users),
            caption: I18n.t("ldap_departments.synchronized_trees.form.sync_users_text")
          )
        end

        tree_form.group(layout: :horizontal, mt: 3) do |buttons|
          buttons.button(
            name: :cancel,
            tag: :a,
            label: I18n.t(:button_cancel),
            scheme: :default,
            href: url_helpers.ldap_departments_synchronized_trees_path
          )
          buttons.submit(
            name: :submit,
            label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
            scheme: :primary
          )
        end
      end
    end
  end
end
