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

RSpec.describe Queries::Projects::Filters::ProgramFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :program }
    let(:type) { :list_optional }
    let(:name) { Project.human_attribute_name(:program) }
  end

  describe "#allowed_values" do
    let(:program) { build_stubbed(:project, workspace_type: "program") }

    before do
      allow(Project)
        .to receive_message_chain(:program, :visible, :map) # rubocop:disable RSpec/MessageChain
        .and_return([[program.name, program.id.to_s]])
    end

    it "returns visible programs" do
      instance = described_class.create!(name: :program, operator: "=", values: [])

      expect(instance.allowed_values).to eq([[program.name, program.id.to_s]])
    end
  end

  describe "#available?" do
    it "is true if any program is visible to the current user" do
      allow(Project)
        .to receive_message_chain(:workspace_type, :visible, :exists?) # rubocop:disable RSpec/MessageChain
        .with("program")
        .with(no_args)
        .with(no_args)
        .and_return(true)

      instance = described_class.create!(name: :program, operator: "=", values: [])

      expect(instance).to be_available
    end

    it "is false if no program is visible to the current user" do
      allow(Project)
        .to receive_message_chain(:workspace_type, :visible, :exists?) # rubocop:disable RSpec/MessageChain
        .with("program")
        .with(no_args)
        .with(no_args)
        .and_return(false)

      instance = described_class.create!(name: :program, operator: "=", values: [])

      expect(instance).not_to be_available
    end
  end

  describe "#apply_to", :with_temporary_session_options do
    subject(:filter) { described_class.create!(name: :program, operator:, values:) }

    let!(:portfolio) { create(:project, workspace_type: "portfolio") }
    let!(:program)   { create(:project, workspace_type: "program", parent: portfolio) }
    let!(:project1)  { create(:project, parent: program) }
    let!(:project2)  { create(:project, parent: portfolio) }
    let!(:orphan)    { create(:project) }

    context 'for "="' do
      let(:operator) { "=" }
      let(:values) { [program.id.to_s] }

      it "returns descendants of the program" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(project1)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }
      let(:values) { [program.id.to_s] }

      it "returns projects that are not descendants of the program" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(portfolio, program, project2, orphan)
      end
    end

    context 'for "*"' do
      let(:operator) { "*" }
      let(:values) { [] }

      it "returns projects that have any program as ancestor" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(project1)
      end
    end

    context 'for "!*"' do
      let(:operator) { "!*" }
      let(:values) { [] }

      it "returns projects without any program as ancestor" do
        result = filter.apply_to(Project.all)

        expect(result).to contain_exactly(portfolio, program, project2, orphan)
      end
    end
  end
end
