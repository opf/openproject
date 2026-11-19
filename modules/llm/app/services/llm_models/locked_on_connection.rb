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
  # A seed applying the environment's values, and any concurrent rename or delete,
  # holds the connection's advisory lock until it commits. Both records are
  # re-read under the lock so a write is judged and cascaded on committed rows.
  module LockedOnConnection
    private

    def service_context(send_notifications:, &)
      in_mutex_context(connection, send_notifications:, &)
    end

    def validate_params
      connection.reload
      model.reload

      super
    end

    def connection
      @connection ||= model.llm_connection
    end
  end
end
