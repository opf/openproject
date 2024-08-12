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

RSpec.describe Query::Results, "Filtering custom fields" do
  shared_let(:user) { create(:admin) }
  shared_let(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      possible_values: %w[A B C]
    )
  end

  def custom_values_for(*names)
    custom_field
      .custom_options
      .where(value: names)
      .pluck(:id)
      .map do |value|
      CustomValue.new(custom_field_id: custom_field.id, value:)
    end
  end

  shared_let(:type) { create(:type_standard, custom_fields: [custom_field]) }
  shared_let(:project) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field])
  end

  shared_let(:wp_a) do
    create(:work_package, subject: "A", type:, project:, custom_values: custom_values_for("A"))
  end

  shared_let(:wp_b) do
    create(:work_package, subject: "B", type:, project:, custom_values: custom_values_for("B"))
  end

  shared_let(:wp_c) do
    create(:work_package, subject: "C", type:, project:, custom_values: custom_values_for("C"))
  end

  shared_let(:wp_a_b) do
    create(:work_package, subject: "A and B", type:, project:, custom_values: custom_values_for("A", "B"))
  end

  shared_let(:wp_b_c) do
    create(:work_package, subject: "B and C", type:, project:, custom_values: custom_values_for("B", "C"))
  end

  shared_let(:wp_a_b_c) do
    create(:work_package, subject: "A B C", type:, project:, custom_values: custom_values_for("A", "B", "C"))
  end

  let(:query) do
    build(:query,
          user:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.add_filter(custom_field.column_name, operator, custom_field.custom_options.where(value: values).pluck(:id))
    end
  end

  let(:query_results) do
    described_class
      .new(query)
      .work_packages
      .pluck(:id)
  end

  before do
    login_as(user)
  end

  shared_examples "filtered work packages" do
    it do
      expect(query_results).to match_array expected.map(&:id)
    end
  end

  describe "filter for is(OR)" do
    let(:operator) { "=" }

    context "when filtering for A" do
      let(:values) { ["A"] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a, wp_a_b, wp_a_b_c] }
      end
    end

    context "when filtering for A OR B" do
      let(:values) { %w[A B] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a, wp_a_b, wp_a_b_c, wp_b, wp_b_c] }
      end
    end

    context "when filtering for A OR B OR C" do
      let(:values) { %w[A B C] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a, wp_a_b, wp_a_b_c, wp_b, wp_b_c, wp_c] }
      end
    end
  end

  describe "filter for is(AND)" do
    let(:operator) { "&=" }

    context "when filtering for A" do
      let(:values) { ["A"] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a, wp_a_b, wp_a_b_c] }
      end
    end

    context "when filtering for A AND B" do
      let(:values) { %w[A B] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a_b, wp_a_b_c] }
      end
    end

    context "when filtering for A AND B AND C" do
      let(:values) { %w[A B C] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_a_b_c] }
      end
    end
  end

  describe "filter for is not" do
    let(:operator) { "!" }

    context "when filtering for A" do
      let(:values) { ["A"] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_b, wp_b_c, wp_c] }
      end
    end

    context "when filtering for A AND B" do
      let(:values) { %w[A B] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [wp_c] }
      end
    end

    context "when filtering for A AND B AND C" do
      let(:values) { %w[A B C] }

      it_behaves_like "filtered work packages" do
        let(:expected) { [] }
      end
    end
  end
end
