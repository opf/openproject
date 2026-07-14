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

RSpec.describe Queries::Projects::Filters::PortfolioFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :portfolio }
    let(:type) { :list_optional }
    let(:name) { Project.human_attribute_name(:portfolio) }
  end

  describe "#allowed_values" do
    let(:portfolio) { build_stubbed(:project, workspace_type: "portfolio") }

    before do
      allow(Project)
        .to receive_message_chain(:portfolio, :visible, :pluck) # rubocop:disable RSpec/MessageChain
        .with(:id)
        .and_return([portfolio.id])
    end

    it "returns visible portfolios" do
      instance = described_class.create!(name: :portfolio, operator: "=", values: [])

      expect(instance.allowed_values).to eq([[portfolio.id, portfolio.id.to_s]])
    end
  end

  describe "#apply_to", :with_temporary_session_options do
    subject(:filter) { described_class.create!(name: :portfolio, operator:, values:) }

    let!(:portfolio) { create(:project, workspace_type: "portfolio") }
    let!(:program)   { create(:project, workspace_type: "program", parent: portfolio) }
    let!(:project1)  { create(:project, parent: program) }
    let!(:project2)  { create(:project, parent: portfolio) }
    let!(:orphan)    { create(:project) }

    context 'for "="' do
      let(:operator) { "=" }
      let(:values) { [portfolio.id.to_s] }

      it "returns descendants of the portfolio" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(program, project1, project2)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }
      let(:values) { [portfolio.id.to_s] }

      it "returns projects that are not descendants of the portfolio" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(portfolio, orphan)
      end
    end

    context 'for "*"' do
      let(:operator) { "*" }
      let(:values) { [] }

      it "returns projects that have any portfolio as ancestor" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(program, project1, project2)
      end
    end

    context 'for "!*"' do
      let(:operator) { "!*" }
      let(:values) { [] }

      it "returns projects without any portfolio as ancestor" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(portfolio, orphan)
      end
    end
  end
end
