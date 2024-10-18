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

module BulkServices
  module ProjectMappings
    class BaseCreateService < ::BaseServices::BaseCallable
      attr_reader :mapping_context

      delegate :incoming_projects, :mapping_model_class, to: :mapping_context

      def initialize(user:, mapping_context: nil)
        super()
        @user = user
        @mapping_context = mapping_context
      end

      def perform(params = {})
        service_call = validate_permissions
        service_call = validate_contract(service_call, params) if service_call.success?
        service_call = perform_bulk_create(service_call) if service_call.success?
        service_call = after_perform(service_call, params) if service_call.success?

        service_call
      end

      private

      def validate_permissions
        return ServiceResult.failure(errors: I18n.t(:label_not_found)) if incoming_projects.empty?

        if @user.allowed_in_project?(permission, incoming_projects)
          ServiceResult.success
        else
          ServiceResult.failure(errors: I18n.t("activerecord.errors.messages.error_unauthorized"))
        end
      end

      def validate_contract(service_call, params)
        extra_attributes = attributes_from_params(params)
        mapping_attributes_for_all_projects = mapping_context.mapping_attributes_for_all_projects(extra_attributes)
        set_attributes_results = mapping_attributes_for_all_projects.map do |mapping_attributes|
          set_attributes(mapping_attributes)
        end

        if (failures = set_attributes_results.select(&:failure?)).any?
          service_call.success = false
          service_call.errors = failures.map(&:errors)
        else
          service_call.result = set_attributes_results.map(&:result)
        end

        service_call
      end

      # override in subclasses to pass additional parameters to the `SetAttributesService`.
      def attributes_from_params(_params)
        {}
      end

      def perform_bulk_create(service_call)
        mapping_model_class.insert_all(
          service_call.result.map { |model| model.attributes.compact },
          unique_by: [:project_id, model_foreign_key_id.to_sym]
        )

        service_call
      end

      def after_perform(service_call, _params)
        service_call # Subclasses can override this method to add additional logic
      end

      def set_attributes(params)
        attributes_service_class
          .new(user: @user,
               model: mapping_model_class.new,
               contract_class: default_contract_class)
          .call(params)
      end

      # @return [Symbol] the permission required to create the mapping
      def permission
        raise NotImplementedError
      end

      # @return [Symbol] the column name of the mapping
      def model_foreign_key_id
        raise NotImplementedError
      end

      def attributes_service_class
        "#{namespace}::SetAttributesService".constantize
      end

      def default_contract_class
        "#{namespace}::UpdateContract".constantize
      end

      def namespace
        self.class.name.deconstantize.pluralize
      end
    end
  end
end
