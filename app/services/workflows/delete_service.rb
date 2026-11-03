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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Workflows
  class DeleteService < ::BaseServices::Delete
    protected

    def default_contract_class = DeleteContract

    def before_perform(service_call)
      self.contract_options = params.slice(:target)

      service_call
    end

    def persist(service_result)
      destroyed = false

      Workflow.transaction do
        repoint_variants(params[:target])
        model.type_variants.reset
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

    def repoint_variants(target)
      return if target.nil?

      model.type_variants.update_all(workflow_id: target.id, updated_at: Time.current)
    end
  end
end
