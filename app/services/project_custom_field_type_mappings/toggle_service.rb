# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ProjectCustomFieldTypeMappings
  class ToggleService < ::BaseServices::Write
    def persist(service_result)
      if ActiveModel::Type::Boolean.new.cast(params[:value])
        create_mapping(service_result)
      else
        destroy_mapping(service_result)
      end

      service_result
    end

    def instance(params)
      instance_class.find_or_initialize_by(
        type_id: params[:type_id],
        custom_field_id: params[:custom_field_id]
      )
    end

    def set_attributes_params(_params)
      {}
    end

    def default_contract_class
      ProjectCustomFieldTypeMappings::UpdateContract
    end

    private

    def create_mapping(service_result)
      return if service_result.result.persisted?

      unless service_result.result.save
        service_result.errors = service_result.result.errors
        service_result.success = false
      end
    end

    def destroy_mapping(service_result)
      return unless service_result.result.persisted?

      service_result.result.destroy!
    rescue StandardError => e
      service_result.errors = e.message
      service_result.success = false
    end
  end
end
