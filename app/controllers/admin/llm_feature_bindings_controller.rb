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
  # Assigns a model to each registered AI feature.
  class LlmFeatureBindingsController < ApplicationController
    layout "admin"
    menu_item :llm_feature_bindings

    before_action :require_feature
    before_action :require_admin
    before_action :set_connection

    def index
      @features = OpenProject::Llm::Features.available
      @bindings = bindings_by_feature_key
    end

    def update
      feature = OpenProject::Llm::Features[params[:id]]
      assign(feature)

      redirect_to llm_feature_bindings_path, status: :see_other
    rescue OpenProject::Llm::UnknownFeature
      render_404
    end

    private

    def set_connection
      @connection = LlmConnection.instance
    end

    # The flag gates the endpoints, not only the menu entry: an unfinished page
    # must not accept writes just because somebody knows the URL.
    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active?
    end

    def bindings_by_feature_key
      @connection.feature_bindings.index_by(&:feature_key)
    end

    def binding_for(feature)
      @connection.feature_bindings.find_or_initialize_by(feature_key: feature.key.to_s)
    end

    def assign(feature)
      binding = build_binding(feature)

      unless binding.save
        flash[:error] = binding.errors.full_messages.join(", ")
        return
      end

      confirm_assignment(feature, probe_capabilities(feature, binding))
    end

    # The probe may just have proven the chosen model cannot do what the feature
    # requires; confirming that save would report a working configuration that
    # Llm::Runtime immediately resolves as incapable.
    def confirm_assignment(feature, verdict)
      if verdict&.blocking?
        flash[:error] = t("admin.llm_feature_bindings.update.model_incapable",
                          feature: feature.label,
                          capability: Llm::Capabilities.label(:embeddings))
      else
        flash[:notice] = t("admin.llm_feature_bindings.update.success", feature: feature.label)
      end
    end

    def build_binding(feature)
      binding = binding_for(feature)
      binding.model_id = params.dig(:llm_feature_binding, :model_id).presence

      # Only ever accepted for the kind of feature they describe; the model
      # rejects them elsewhere, and they are not read at all for a chat feature.
      assign_embedding_settings(binding) if feature.embedding?

      binding
    end

    # The prefixes are stored exactly as typed. The trailing space in "passage: "
    # is load-bearing for the E5 and BGE families, so stripping would silently
    # degrade retrieval.
    def assign_embedding_settings(binding)
      settings = params.fetch(:llm_feature_binding, {})

      binding.dimensions = settings[:dimensions].presence
      binding.input_prefix = settings[:input_prefix]
      binding.query_prefix = settings[:query_prefix]
    end

    # The verdict that actually matters is the one for the model an administrator
    # just chose, so it is fetched now rather than left unknown until first use.
    def probe_capabilities(feature, binding)
      return if feature.requires.empty? || binding.model_id.blank?

      LlmConnections::DetectCapabilitiesService.new(@connection).detect(binding.model_id).result
    end
  end
end
