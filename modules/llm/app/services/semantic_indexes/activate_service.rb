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

module SemanticIndexes
  class ActivateService < ::BaseServices::BaseCallable
    attr_reader :user, :model

    def initialize(user:, model:)
      super()
      @user = user
      @model = model
    end

    protected

    def perform
      unless user.admin? && user.active?
        return ServiceResult.failure(result: model, message: I18n.t(:notice_not_authorized))
      end

      return pgvector_missing unless OpenProject::Llm::Pgvector.available?

      binding = SemanticIndex.semantic_search_binding
      binding.semantic_index = model

      if binding.save
        ServiceResult.success(result: model)
      else
        ServiceResult.failure(result: model, errors: binding.errors)
      end
    end

    private

    def pgvector_missing
      ServiceResult.failure(result: model,
                            message: I18n.t("admin.semantic_indexes.indexing.not_ready.pgvector_missing"))
    end
  end
end
