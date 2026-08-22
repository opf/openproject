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
  # Confirms disconnecting from the LLM server.
  #
  # Disconnecting clears the credential and switches the connection off. It does
  # not delete anything: the endpoint, the model catalogue, the capability
  # verdicts and every feature binding are kept, so reconnecting is a matter of
  # entering the key again.
  #
  # That is also why there is no confirmation checkbox -- nothing here is
  # irreversible. A destroying variant would have been, and would have taken the
  # locked embedding bindings with it: those are the only record that a vector
  # index exists and which model and dimension it was written under, and
  # dependent: :delete_all bypasses the guard that protects them.
  class DisconnectDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    TEST_SELECTOR = "llm-connection--disconnect-dialog"

    alias_method :connection, :model

    def form_arguments
      { action: url_helpers.disconnect_llm_connection_path, method: :post }
    end
  end
end
