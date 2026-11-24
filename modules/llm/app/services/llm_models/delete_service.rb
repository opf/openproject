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
  class DeleteService < ::BaseServices::Delete
    include LockedOnConnection

    # Verdicts are keyed by the identifier string, not by foreign key, and
    # must not carry over to a model re-added under the same name.
    def persist(service_result)
      defaults = model.connection_defaults

      super.tap do |call|
        next unless call.success?

        connection.capability_verdicts.where(model_id: model.external_id).delete_all
        clear_connection_defaults(defaults)
      end
    end

    private

    def clear_connection_defaults(defaults)
      return if defaults.empty?

      connection.update_columns(defaults.index_with(nil).merge(env_provisioned_at: nil, env_fingerprint: nil))
    end
  end
end
