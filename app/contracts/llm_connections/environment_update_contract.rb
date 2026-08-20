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
  # Used when the connection is provisioned from the environment.
  #
  # Inherits from BaseContract, not UpdateContract: seeding must never reach out
  # to the LLM server, because the container it runs in may well start before the
  # server does. It also lifts the "configured from environment is read-only"
  # guard, since this is the code path that legitimately writes those values.
  class EnvironmentUpdateContract < BaseContract
    def not_configured_from_env = nil

    # On a fresh installation the seed runs before any model synchronisation, so
    # there is no catalogue to validate a default model against. A wrong id is
    # surfaced afterwards, the same way as a model that vanished: the binding
    # shows as no longer offered.
    def default_models_offered_by_server = nil
  end
end
