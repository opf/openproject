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
module LlmModels
  class UpdateService < ::BaseServices::Update
    include Persistence
    include LockedOnConnection

    private

    def before_perform(service_call)
      @stored_model_type = model.model_type.to_s

      super
    end

    # A type is pinned only when it differs from the stored one, leaving an
    # unchanged type open to correction by a probe or a refresh.
    def type_chosen?
      super && params[:model_type].to_s != @stored_model_type
    end

    def after_save(llm_model, pin_type:)
      cascade_rename(llm_model)

      super
    end

    # Everything that points at a model does so by its identifier string, so a
    # rename has to carry them along or it silently orphans them. A locked
    # binding follows too: renaming corrects the name, it does not change the
    # model. The connection defaults reference the row and follow on their own.
    def cascade_rename(llm_model)
      previous, current = llm_model.saved_change_to_external_id
      return if previous.blank?

      connection.capability_verdicts.where(model_id: previous).update_all(model_id: current)
      connection.feature_bindings.where(model_id: previous).update_all(model_id: current)
      connection.update_columns(env_provisioned_at: nil, env_fingerprint: nil) if llm_model.connection_defaults.any?
    end
  end
end
