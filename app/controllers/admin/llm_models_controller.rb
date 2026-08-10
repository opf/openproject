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

module Admin
  # Models an administrator enters by hand.
  #
  # Necessary because not every OpenAI-compatible server exposes a model list.
  # A gateway may route /v1/chat/completions and nothing else, in which case the
  # operator knows the model name and OpenProject cannot discover it.
  class LlmModelsController < ApplicationController
    layout "admin"
    menu_item :llm_connection

    before_action :require_admin
    before_action :set_connection

    def create
      llm_model = @connection.models.new(model_params.merge(manual: true))

      if llm_model.save
        flash[:notice] = t(".success", model: llm_model.external_id)
      else
        flash[:error] = llm_model.errors.full_messages.join(", ")
      end

      redirect_to llm_connection_path, status: :see_other
    end

    def destroy
      llm_model = @connection.models.manual.find(params.expect(:id))
      llm_model.destroy!

      flash[:notice] = t(".success", model: llm_model.external_id)
      redirect_to llm_connection_path, status: :see_other
    end

    private

    def set_connection
      @connection = LlmConnection.instance
    end

    def model_params
      params.expect(llm_model: %i[external_id display_name])
    end
  end
end
