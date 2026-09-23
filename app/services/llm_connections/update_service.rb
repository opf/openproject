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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  class UpdateService < BaseServices::Update
    # Whether the catalogue should be refreshed now that the save is through: the
    # connection points somewhere else than it did, which covers both the first
    # fill and a later switch of server. Nothing an administrator curated is lost
    # by refreshing, since the sync keeps manual entries and admin verdicts.
    #
    # Callers refresh once the service has returned. BaseContracted#perform runs
    # inside OpenProject::Mutex.with_advisory_lock_transaction, so a refresh from
    # in here would hold an open transaction and the connection's advisory lock
    # for up to the client's twenty-second probe timeout.
    def self.models_to_refresh?(connection)
      connection.saved_changes.keys.intersect?(LlmServerValidator::CONNECTION_ATTRIBUTES)
    end

    private

    def after_perform(service_call)
      super.tap do
        next unless service_call.success?

        Setting.llm_features_enabled = model.llm_features_enabled
      end
    end
  end
end
