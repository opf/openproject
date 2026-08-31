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
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class CreateVariantService < ::BaseServices::Create
    def initialize(user:, type:, contract_class: nil, contract_options: {})
      @type = type
      super(user:, contract_class:, contract_options:)
    end

    protected

    attr_reader :type

    def instance_class = TypeVariant

    def instance(params)
      type.variants.new(workflow: workflow_for(params[:project])).tap do |variant|
        TypeVariant::ASPECTS.each { |aspect| variant.public_send(:"#{aspect}_source=", type.default_variant) }
      end
    end

    def after_perform(service_call)
      workflow = service_call.result.workflow
      Workflows::StatusTransition.copy(base_workflow, nil, workflow, nil) if workflow.project_specific?

      service_call
    end

    def default_contract_class = CreateVariantContract

    private

    # A variant only its project can see would otherwise edit the type's transitions for every
    # other project through the workflow they share.
    def workflow_for(project)
      return base_workflow if project.nil?

      Workflow.build_with_available_name(base_workflow.name, project:)
    end

    def base_workflow = type.default_variant.workflow
  end
end
