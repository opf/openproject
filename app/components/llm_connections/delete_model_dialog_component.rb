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
  class DeleteModelDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    TEST_SELECTOR = "llm-model--delete-dialog"

    alias_method :llm_model, :model

    def form_arguments
      { action: url_helpers.llm_model_path(llm_model), method: :delete }
    end

    # Named so the message says what is actually at stake. The connection
    # defaults count as bindings here -- deleting their model breaks every
    # feature that inherits them.
    def bound_features
      affected_defaults
    end

    def affected_defaults
      %i[default_chat_model_id default_embedding_model_id]
        .select { |attribute| llm_model.llm_connection.public_send(attribute) == llm_model.external_id }
        .map { |attribute| LlmConnection.human_attribute_name(attribute) }
    end
  end
end
