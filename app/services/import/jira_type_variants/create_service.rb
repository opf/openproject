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

module Import
  module JiraTypeVariants
    class CreateService
      include Import::JiraOpenProjectReferenceCreation

      def initialize(user:, jira_import:)
        @user = user
        @jira_import = jira_import
      end

      def call(type:, project:)
        return not_allowed_failure(type) unless type.allow_project_variants?

        result = nil

        # A block joined to the caller's transaction would swallow the Rollback without undoing anything.
        TypeVariant.transaction(requires_new: true) do
          result = create_variant(type:, project:)
          raise ActiveRecord::Rollback if result.failure?
        end

        result
      end

      private

      attr_reader :user, :jira_import

      def not_allowed_failure(type)
        ServiceResult.failure(message: I18n.t("admin.jira.run.project_variants_not_allowed", type: type.name))
      end

      def create_variant(type:, project:)
        base_variant = type.default_variant
        label = "#{type.name} (Jira #{project.identifier})"

        form_call = create_form(label:, base_variant:)
        return form_call if form_call.failure?

        workflow_call = create_workflow(label:, base_variant:)
        return workflow_call if workflow_call.failure?

        variant_call = create_type_variant(type:, project:, form: form_call.result, workflow: workflow_call.result)
        return variant_call if variant_call.failure?

        variant_call
      end

      def create_form(label:, base_variant:)
        name = FormConfiguration.available_name(label)
        FormConfigurations::CreateService
          .new(user:)
          .call(name:, copy_from_id: base_variant.form_configuration_id)
          .on_success { store_reference(it.result) }
      end

      def create_workflow(label:, base_variant:)
        name = Workflow.available_name(label)
        Workflows::CreateService
          .new(user:)
          .call(name:, copy_from_id: base_variant.workflow_id)
          .on_success { store_reference(it.result) }
      end

      def create_type_variant(type:, project:, form:, workflow:)
        description = I18n.t("admin.jira.run.type_variant_description", project_name: project.name)
        WorkPackageTypes::CreateVariantService
          .new(user:, type:)
          .call(variant_name: type.name,
                description:,
                project_id: project.id,
                form_configuration_id: form.id,
                workflow_id: workflow.id)
          .on_success { store_reference(it.result) }
      end

      def store_reference(record)
        create_reference!(op_leg: record, jira_leg: nil, jira_import:, uses_existing: false)
      end
    end
  end
end
