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
  # Removes a named variant.
  #
  # What refuses it is on the model, where the database constraints it mirrors also are: a
  # project applying the variant, or another variant borrowing configuration from it. Both
  # arrive here as errors on the record.
  class DeleteVariantService < ::BaseServices::Delete
    protected

    def default_contract_class = DeleteVariantContract

    def before_perform(service_call)
      self.contract_options = params.slice(:target)

      service_call
    end

    def persist(service_result)
      destroyed = false

      ActiveRecord::Base.transaction do
        switch_applying_projects(params[:target])
        model.project_types.reset
        destroyed = model.destroy
        raise ActiveRecord::Rollback unless destroyed
      end

      unless destroyed
        service_result.success = false
        service_result.errors = model.errors
      end

      service_result
    end

    private

    def switch_applying_projects(target)
      return if target.nil?

      model.projects.to_a.each { |project| switch(project, target) }
    end

    def switch(project, target)
      result = ::Projects::Types::SwitchVariantService.new(user:, model: project).call(source: model, target:)
      return if result.success?

      model.errors.add(:base, :migration_failed, project: project.name, reason: result.errors.full_messages.to_sentence)
      raise ActiveRecord::Rollback
    end
  end
end
