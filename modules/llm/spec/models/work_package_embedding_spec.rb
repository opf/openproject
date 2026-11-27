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

require "spec_helper"
require_module_spec_helper

RSpec.describe WorkPackageEmbedding do
  describe ".vector_literal" do
    it "converts an array of numbers to the string representation of a vector" do
      literal = described_class.vector_literal(Array.new(described_class::DIMENSIONS, 0.1))

      expect(JSON.parse(literal)).to all(eq(0.1))
    end

    it "formats the vector as a pgvector literal zero-padded to the column width" do
      padding = Array.new(described_class::DIMENSIONS - 3, "0.0")
      values = ["1.0", "0.5", "-2.0", *padding].join(",")
      expected = "[#{values}]"

      expect(described_class.vector_literal([1, 0.5, -2])).to eq(expected)
    end

    it "raises on vectors wider than the column" do
      expect { described_class.vector_literal(Array.new(described_class::DIMENSIONS + 1, 0.1)) }
        .to raise_error(ArgumentError)
    end

    it "raises on non-numeric values" do
      expect { described_class.vector_literal(["0.1); DROP TABLE work_packages; --"]) }
        .to raise_error(ArgumentError)
    end
  end

  it "stores embeddings narrower than the column" do
    create(:work_package_embedding, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, embedding: Array.new(1536, 0.1))

    expect(described_class.count).to eq(2)
  end

  describe ".work_package_ids_within_search_distance_sql" do
    let(:semantic_index) { create(:semantic_index) }
    let(:vector) { described_class.vector_literal([0.1, 0.2, 0.3]) }

    it "applies the distance threshold outside the ORDER BY distance + LIMIT query that uses the HNSW index" do
      sql = described_class.work_package_ids_within_search_distance_sql(vector,
                                                                        semantic_index_id: semantic_index.id,
                                                                        work_packages: WorkPackage.all,
                                                                        limit: 10)

      expect(sql).to match(/AS MATERIALIZED \(.*ORDER BY distance LIMIT 10\) SELECT .* WHERE distance < /)
    end

    it "returns the closest work packages within the search distance even when only few are" do
      closest = create(:work_package)
      outside = create(:work_package)
      create(:work_package_embedding, work_package: closest, semantic_index:, embedding: [0.1, 0.2, 0.3])
      create(:work_package_embedding, work_package: outside, semantic_index:, embedding: [-0.1, -0.2, -0.3])

      sql = described_class.work_package_ids_within_search_distance_sql(vector,
                                                                        semantic_index_id: semantic_index.id,
                                                                        work_packages: WorkPackage.all,
                                                                        limit: 10)

      expect(described_class.connection.select_values(sql)).to eq [closest.id]
    end

    it "returns the work package ids within the search distance, most similar first" do
      closest = create(:work_package)
      farther = create(:work_package)
      outside = create(:work_package)
      create(:work_package_embedding, work_package: closest, semantic_index:, embedding: [0.1, 0.2, 0.3])
      create(:work_package_embedding, work_package: farther, semantic_index:, embedding: [0.2, 0.2, 0.2])
      create(:work_package_embedding, work_package: outside, semantic_index:, embedding: [-0.1, -0.2, -0.3])
      # Same distance as the closest, but in another index: must not leak in.
      create(:work_package_embedding, work_package: outside, embedding: [0.1, 0.2, 0.3])

      sql = described_class.work_package_ids_within_search_distance_sql(vector,
                                                                        semantic_index_id: semantic_index.id,
                                                                        work_packages: WorkPackage.all)

      expect(described_class.connection.select_values(sql)).to eq [closest.id, farther.id]
    end

    it "fills the limit from the given work packages only" do
      excluded = create(:work_package)
      included = create(:work_package)
      create(:work_package_embedding, work_package: excluded, semantic_index:, embedding: [0.1, 0.2, 0.3])
      create(:work_package_embedding, work_package: included, semantic_index:, embedding: [0.2, 0.2, 0.2])

      sql = described_class.work_package_ids_within_search_distance_sql(vector,
                                                                        semantic_index_id: semantic_index.id,
                                                                        work_packages: WorkPackage.where(id: included.id),
                                                                        limit: 1)

      expect(described_class.connection.select_values(sql)).to eq [included.id]
    end

    it "caps the candidates at the given limit, keeping the most similar" do
      closest = create(:work_package)
      farther = create(:work_package)
      create(:work_package_embedding, work_package: closest, semantic_index:, embedding: [0.1, 0.2, 0.3])
      create(:work_package_embedding, work_package: farther, semantic_index:, embedding: [0.2, 0.2, 0.2])

      sql = described_class.work_package_ids_within_search_distance_sql(vector,
                                                                        semantic_index_id: semantic_index.id,
                                                                        work_packages: WorkPackage.all,
                                                                        limit: 1)

      expect(described_class.connection.select_values(sql)).to eq [closest.id]
    end
  end
end
