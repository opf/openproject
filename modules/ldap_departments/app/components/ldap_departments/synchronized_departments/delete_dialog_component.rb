# frozen_string_literal: true

module LdapDepartments
  module SynchronizedDepartments
    class DeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      def initialize(department:)
        super()
        @department = department
      end

      private

      attr_reader :department

      def name
        department.group&.name
      end

      def form_arguments
        {
          action: ldap_departments_synchronized_department_path(department_id: department.id),
          method: :delete
        }
      end

      def title
        I18n.t("ldap_departments.synchronized_departments.destroy.title", name:)
      end

      def heading
        I18n.t("ldap_departments.synchronized_departments.destroy.heading", name:)
      end

      def confirmation_text
        I18n.t("ldap_departments.synchronized_departments.destroy.confirmation", name:)
      end

      def info_text
        I18n.t("ldap_departments.synchronized_departments.destroy.info")
      end
    end
  end
end
