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

module Llm
  module Validators
    # Whether each registered feature can actually run.
    #
    # Driven by Llm::Runtime, so the health report and the runtime can never
    # disagree about what is usable. That makes this the most informative group
    # in the report: it answers "will the AI features work" rather than "is the
    # server up".
    #
    # The check keys are fixed and the feature names travel in the result
    # context. Per-feature keys would need a translation per feature and would
    # break HealthReports::ResultComponent#text, which resolves a check's label
    # from its key.
    class FeatureValidator < HealthReports::ValidatorGroup
      def self.key = :features

      private

      def validate
        register_checks(:bindings_resolvable, :active_semantic_index_intact)

        bindings_resolvable
        active_semantic_index_intact
      end

      def bindings_resolvable
        by_status = resolutions.group_by(&:status)

        if (incapable = by_status[:incapable]).present?
          fail_check(:bindings_resolvable, :features_incapable,
                     context: { features: labels(incapable),
                                capabilities: capability_labels(incapable) })
        end

        if (missing = by_status[:model_missing]).present?
          fail_check(:bindings_resolvable, :features_model_missing, context: { features: labels(missing) })
        end

        if (unbound = by_status[:unbound]).present?
          return warn_check(:bindings_resolvable, :features_unbound, context: { features: labels(unbound) })
        end

        pass_check(:bindings_resolvable)
      end

      # If the model an index was built with has left the catalogue, queries can
      # no longer be embedded consistently with the stored vectors.
      def active_semantic_index_intact
        semantic_index = subject.feature_bindings.find_by(feature_key: "semantic_search")&.semantic_index

        if semantic_index.nil? || subject.available_model_ids.include?(semantic_index.model_id)
          return pass_check(:active_semantic_index_intact)
        end

        fail_check(:active_semantic_index_intact, :semantic_index_model_missing,
                   context: { title: semantic_index.title, model: semantic_index.model_id })
      end

      def resolutions
        # Embedding features take their model from the active Semantic Index.
        @resolutions ||= OpenProject::Llm::Features.available.reject(&:embedding?).map do |feature|
          Llm::Runtime.for(feature.key)
        end
      end

      def labels(resolutions) = resolutions.map { |resolution| resolution.feature.label }.join(", ")

      def capability_labels(resolutions)
        resolutions.flat_map(&:missing_capabilities)
                   .uniq
                   .map { |capability| Llm::Capabilities.label(capability) }
                   .join(", ")
      end
    end
  end
end
