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

RSpec.describe SharingStrategies::ProjectQueryStrategy do
  let(:entity) { instance_double(ProjectQuery, editable?: true, visible?: true) }
  let(:user) { build_stubbed(:user) }
  let(:query_params) { {} }
  let(:strategy) { described_class.new(entity, query_params:, user:) }
  let(:edit_project_query_role) { build_stubbed(:edit_project_query_role) }
  let(:view_project_query_role) { build_stubbed(:view_project_query_role) }

  describe "#available_roles" do
    before do
      edit_project_query_role
      view_project_query_role
      allow(ProjectQueryRole).to receive(:pluck)
        .with(:builtin, :id)
        .and_return({ Role::BUILTIN_PROJECT_QUERY_EDIT => edit_project_query_role.id,
                      Role::BUILTIN_PROJECT_QUERY_VIEW => view_project_query_role.id })
    end

    it "returns the appropriate role hash collection" do
      available_roles = strategy.available_roles
      expect(available_roles).to contain_exactly(
        {
          label: "Edit",
          value: edit_project_query_role.id,
          description: "Can view, share and edit this project list."
        }, {
          label: "View",
          value: view_project_query_role.id,
          description: "Can view this project list.",
          default: true
        }
      )
    end
  end

  describe "#manageable?" do
    context "when the entity is editable" do
      it { expect(strategy.manageable?).to be(true) }
    end

    context "when the entity is not editable" do
      let(:entity) { instance_double(ProjectQuery, editable?: false, visible?: true) }

      it { expect(strategy.manageable?).to be(false) }
    end
  end

  describe "#viewable?" do
    context "when the entity is visible" do
      it { expect(strategy.viewable?).to be(true) }
    end

    context "when the entity is not visible" do
      let(:entity) { instance_double(ProjectQuery, editable?: true, visible?: false) }

      it { expect(strategy.viewable?).to be(false) }
    end
  end

  describe "#create_contract_class" do
    it { expect(strategy.create_contract_class).to eq(Shares::ProjectQueries::CreateContract) }
  end

  describe "#update_contract_class" do
    it { expect(strategy.update_contract_class).to eq(Shares::ProjectQueries::UpdateContract) }
  end

  describe "#delete_contract_class" do
    it { expect(strategy.delete_contract_class).to eq(Shares::ProjectQueries::DeleteContract) }
  end

  describe "#additional_body_components" do
    it do
      expect(strategy.additional_body_components)
        .to contain_exactly(Shares::ProjectQueries::PublicFlagComponent,
                            Shares::ProjectQueries::ProjectAccessWarningComponent)
    end
  end

  describe "#empty_state_component" do
    it { expect(strategy.empty_state_component).to eq(Shares::ProjectQueries::EmptyStateComponent) }
  end
end
