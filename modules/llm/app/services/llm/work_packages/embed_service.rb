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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  module WorkPackages
    # Generates and stores embeddings for one or more work packages in a single
    # API call.
    #
    # Returns :ok on success or raises on LLM error so the caller's retry
    # mechanism can handle it.
    class EmbedService
      def initialize(work_packages)
        @work_packages = Array(work_packages)
      end

      def call
        raise "no binding" unless binding_ready?

        texts = work_packages.map { |wp| EmbeddableText.for(wp) }
        result = session.embed(texts, model: binding.resolved_model_id, dimensions: binding.dimensions)

        work_packages.zip(result.vectors).each { |wp, vectors| upsert(wp, vectors) }
        lock_binding_on_first_write
        :ok
      end

      private

      attr_reader :work_packages

      def binding
        @binding ||= LlmConnection.active_connection
                                  &.feature_bindings
                                  &.find_or_initialize_by(feature_key: "semantic_search")
      end

      def binding_ready?
        binding.present? && binding.resolved_model_id.present?
      end

      def session
        @session ||= Llm::Session.for(binding.llm_connection)
      end

      def upsert(work_package, vectors)
        record = WorkPackageEmbedding.find_or_initialize_by(work_package_id: work_package.id)
        record.model_id = binding.resolved_model_id
        record.dimensions = binding.dimensions || vectors.length
        record.embedding = vectors
        record.save!
      end

      def lock_binding_on_first_write
        return if binding.locked?

        binding.update!(locked_at: Time.current)
      end
    end
  end
end
