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

module ResourcePlannerViews
  class CreateService < ::BaseServices::Create
    protected

    # STI sets `type` during `.new`, before the model is extended with
    # ChangedBySystem; mark that initial change as system-made so the contract
    # does not flag `type` as a user-written readonly attribute.
    def instance(_params)
      view = model || PersistedView.new
      view.extend(OpenProject::ChangedBySystem) unless view.is_a?(OpenProject::ChangedBySystem)
      view.changed_by_system(view.changes)
      view
    end

    # View and query are saved in one transaction so a failed view validation
    # rolls back the query as well.
    def persist(service_result)
      view = service_result.result
      ApplicationRecord.transaction do
        ensure_query!(view)
        super
      end
    end

    # The new-planner flow intentionally leaves `default_view_id` unset at
    # creation; fill it from the first created child here.
    def after_perform(call)
      return call unless call.success?

      view = call.result
      planner = view.parent
      planner.update!(default_view_id: view.id) if planner.is_a?(ResourcePlanner) && planner.default_view_id.blank?

      call
    end

    private

    def ensure_query!(view)
      return if view.query.present?
      return unless view.respond_to?(:build_default_query)

      query = view.build_default_query
      return if query.nil?

      query.save!
      view.query = query
    end
  end
end
