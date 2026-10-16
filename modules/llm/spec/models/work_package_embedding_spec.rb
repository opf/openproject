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

require "spec_helper"
require_module_spec_helper

RSpec.describe WorkPackageEmbedding do
  describe ".vector_literal" do
    it "formats the vector as a pgvector literal zero-padded to the column width" do
      padding = Array.new(described_class::DIMENSIONS - 3, "0.0")
      values = ["1.0", "0.5", "-2.0", *padding].join(",")
      expected = "[#{values}]"

      expect(described_class.vector_literal([1, 0.5, -2])).to eq(expected)
    end

    it "does not pad a vector that already has the column width" do
      literal = described_class.vector_literal(Array.new(described_class::DIMENSIONS, 0.1))

      expect(JSON.parse(literal)).to all(eq(0.1))
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
end
