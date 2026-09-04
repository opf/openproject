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

require "spec_helper"

RSpec.describe "Costs attribute group cost type availability" do # rubocop:disable RSpec/DescribeClass
  let(:type) { create(:type) }
  let(:type_variant) { type.default_variant }
  let(:project) { build_stubbed(:project) }

  # Unit-cost attributes (and the overall total they feed) are meaningless without
  # a cost type, so they are hidden when none is available.
  let(:cost_type_dependent_attributes) { %i[overall_costs material_costs costs_by_type] }
  # Labor costs (time entries) and budgets do not depend on cost types and stay visible.
  let(:cost_type_independent_attributes) { %i[labor_costs budget] }

  before do
    allow(project).to receive_messages(costs_enabled?: true, module_enabled?: true)
  end

  def passes_constraint?(attribute)
    type_variant.passes_attribute_constraint?(attribute, project:)
  end

  context "when at least one cost type is available in the project" do
    before { allow(project).to receive(:cost_types_available?).and_return(true) }

    it "keeps every cost attribute in the work package form configuration" do
      (cost_type_dependent_attributes + cost_type_independent_attributes).each do |attribute|
        expect(passes_constraint?(attribute)).to be(true), "expected #{attribute} to be shown"
      end
    end
  end

  context "when no cost type is available in the project" do
    before { allow(project).to receive(:cost_types_available?).and_return(false) }

    it "hides the cost-type-dependent attributes" do
      cost_type_dependent_attributes.each do |attribute|
        expect(passes_constraint?(attribute)).to be(false), "expected #{attribute} to be hidden"
      end
    end

    it "still shows labor costs and the budget" do
      cost_type_independent_attributes.each do |attribute|
        expect(passes_constraint?(attribute)).to be(true), "expected #{attribute} to stay shown"
      end
    end
  end
end
