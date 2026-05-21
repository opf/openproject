# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages::Dialogs
  class CreateForm < ApplicationForm
    include CustomFields::CustomFieldRendering

    attr_reader :work_package, :wrapper_id, :contract

    def initialize(work_package:, wrapper_id:)
      super()

      @work_package = work_package
      @schema = API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:)
      @wrapper_id = wrapper_id
      @contract = WorkPackages::CreateContract.new(work_package, User.current)
    end

    form do |f|
      f.project_autocompleter(
        name: :project_id,
        required: true,
        label: Project.model_name.human,
        visually_hide_label: true,
        input_width: :large,
        autocomplete_options: {
          multiple: false,
          clearable: false,
          focusDirectly: false,
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.available_projects_on_create,
          model: { id: work_package.project_id, name: work_package.project&.name },
          hiddenFieldAction: "change->work-packages--create-dialog#updateProject",
          append_to: wrapper_id,
          data: { test_selector: "work_package_create_dialog_project" }
        }
      )

      f.autocompleter(
        name: :type_id,
        required: true,
        include_blank: false,
        input_width: :small,
        label: Type.model_name.human,
        visually_hide_label: true,
        autocomplete_options: {
          multiple: false,
          decorated: true,
          clearable: false,
          focusDirectly: false,
          hiddenFieldAction: "change->work-packages--create-dialog#refreshForm",
          append_to: wrapper_id,
          data: { test_selector: "work_package_create_dialog_type" }
        }
      ) do |select|
        contract
          .assignable_types
          .pluck(:id, :name)
          .map do |value, label|
          select.option(label:,
                        value:,
                        classes: "__hl_inline_type_#{value}",
                        selected: work_package.type_id == value)
        end
      end

      f.text_field(
        name: :subject,
        label: WorkPackage.human_attribute_name(:subject),
        required: true,
        autofocus: autofocus_subject?,
        input_width: :large,
        disabled: !@schema.writable?(:subject)
      )

      f.work_package_autocompleter(
        name: :parent_id,
        label: WorkPackage.human_attribute_name(:parent),
        required: false,
        input_width: :large,
        autocomplete_options: {
          multiple: false,
          clearable: true,
          focusDirectly: false,
          defaultData: false,
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.work_packages_by_project(work_package.project_id),
          model: parent_model,
          append_to: wrapper_id,
          data: { test_selector: "work_package_create_dialog_parent" }
        }
      )

      f.rich_text_area(
        name: :description,
        label: WorkPackage.human_attribute_name(:description),
        rich_text_options: {
          resource: work_package,
          showAttachments: false
        },
        disabled: !@schema.writable?(:description)
      )

      render_custom_fields(form: f)

      # Keep hidden fields for relevant changes
      work_package.changes
                  .slice(*writable_attributes)
                  .except(:description, :subject, :type_id, :project_id, :parent_id)
                  .each do |attribute, value|
        f.hidden(name: attribute, value:)
      end
    end

    def additional_custom_field_input_arguments
      { wrapper_id: }
    end

    def autofocus_subject?
      work_package.errors.empty? && work_package.custom_values.all? { |cv| cv.errors.empty? }
    end

    def parent_model
      return nil unless work_package.parent_id

      { id: work_package.parent_id, name: work_package.parent&.subject }
    end

    private

    def custom_fields
      @custom_fields ||= work_package.available_custom_fields.select(&:required?)
    end

    def writable_attributes
      contract = WorkPackages::CreateContract.new(work_package, User.current)
      contract.writable_attributes
    end
  end
end
