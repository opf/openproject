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
  module WorkPackages
    class EmbedService
      def initialize(work_packages)
        @work_packages = Array(work_packages)
      end

      def call
        return if work_packages.empty?

        raise Llm::Errors::NotReady, resolution.status unless resolution.ready?

        vectors = resolution.embed(texts, dimensions: binding.dimensions).vectors

        store(vectors)
        lock_binding_on_first_write
      end

      private

      attr_reader :work_packages

      def resolution
        @resolution ||= Llm::Runtime.for(:semantic_search)
      end

      def binding
        @binding ||= resolution.connection
                             .feature_bindings
                             .find_or_initialize_by(feature_key: "semantic_search")
      end

      def texts
        context_window = resolution.connection.models.find_by(external_id: resolution.model_id)&.context_window

        work_packages.map { |wp| EmbeddableText.for(wp, context_window:) }
      end

      def store(vectors)
        rows = work_packages.zip(vectors).map do |work_package, vector|
          { work_package_id: work_package.id, embedding: WorkPackageEmbedding.vector_literal(vector) }
        end

        upsert(rows)
      end

      def upsert(rows)
        return if rows.empty?

        WorkPackageEmbedding.transaction(requires_new: true) do
          WorkPackageEmbedding.upsert_all(rows, unique_by: :work_package_id)
        end
      rescue ActiveRecord::InvalidForeignKey
        existing_ids = WorkPackage.where(id: rows.pluck(:work_package_id)).ids
        upsert(rows.select { |row| existing_ids.include?(row[:work_package_id]) })
      end

      def lock_binding_on_first_write
        return if binding.locked?

        binding.update!(locked_at: Time.current)
      end
    end
  end
end
