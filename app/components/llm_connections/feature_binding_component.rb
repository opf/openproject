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
  # One feature's row on the model assignment page.
  class FeatureBindingComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(feature:, connection:, binding: nil)
      super(feature)
      @feature = feature
      @connection = connection
      @binding = binding
    end

    # The record the select binds to. A feature without a stored binding still
    # needs one so the form has a model_id to read.
    def form_model
      binding || connection.feature_bindings.new(feature_key: feature.key.to_s)
    end

    # Not named +options+: ApplicationComponent already owns that name and
    # initialises it to an empty hash, which silently swallowed the memoisation.
    def model_options
      @model_options ||= SelectableModelsQuery.new(connection, feature).call
    end

    def inherit_label
      if default_model_id.present?
        I18n.t("admin.llm_feature_bindings.inherit_with_default", model: default_model_id)
      else
        I18n.t("admin.llm_feature_bindings.inherit_without_default")
      end
    end

    def locked? = binding&.locked?

    def dangling? = binding&.dangling?

    private

    attr_reader :feature, :connection, :binding

    def default_model_id
      feature.embedding? ? connection.default_embedding_model_id : connection.default_chat_model_id
    end

    def form_url
      url_helpers.llm_feature_binding_path(feature.key)
    end
  end
end
