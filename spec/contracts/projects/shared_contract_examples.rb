#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples_for 'project contract' do
  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end
  let!(:allowed_to) do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, permission_project|
      permissions.include?(permission) && project == permission_project
    end
  end
  let(:project_name) { 'Project name' }
  let(:project_identifier) { 'project_identifier' }
  let(:project_description) { 'Project description' }
  let(:project_active) { true }
  let(:project_public) { true }
  let(:project_status) { FactoryBot.build_stubbed(:project_status) }
  let(:project_parent) do
    FactoryBot.build_stubbed(:project)
  end
  let(:parent_assignable) { true }
  let!(:assignable_parents) do
    assignable_parents_scope = double('assignable parents scope')
    assignable_parents = double('assignable parents')

    allow(Project)
      .to receive(:allowed_to)
      .with(current_user, :add_subprojects)
      .and_return assignable_parents_scope

    allow(assignable_parents_scope)
      .to receive(:where)
      .and_return(assignable_parents_scope)

    allow(assignable_parents_scope)
      .to receive(:not)
      .with(id: project.self_and_descendants)
      .and_return(assignable_parents)

    if project_parent
      allow(assignable_parents)
        .to receive(:where)
        .with(id: project_parent.id)
        .and_return(assignable_parents_scope)

      allow(assignable_parents_scope)
        .to receive(:exists?)
        .and_return(parent_assignable)
    end

    assignable_parents
  end

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  it_behaves_like 'is valid'

  context 'if the name is nil' do
    let(:project_name) { nil }

    it 'is invalid' do
      expect_valid(false, name: %i(blank))
    end
  end

  context 'if the identifier is nil' do
    let(:project_identifier) { nil }

    it 'is invalid' do
      expect_valid(false, identifier: %i(blank))
    end
  end

  context 'if the description is nil' do
    let(:project_description) { nil }

    it_behaves_like 'is valid'
  end

  context 'if the parent is nil' do
    let(:project_parent) { nil }

    it_behaves_like 'is valid'
  end

  context 'if the parent is not in the set of assignable_parents' do
    let(:parent_assignable) { false }

    it 'is invalid' do
      expect_valid(false, parent: %i(does_not_exist))
    end
  end

  context 'if active is nil' do
    let(:project_active) { nil }

    it 'is invalid' do
      expect_valid(false, active: %i(blank))
    end
  end

  context 'if status is nil' do
    let(:project_status) { nil }

    it_behaves_like 'is valid'
  end

  context 'if status code is invalid' do
    before do
      allow(project_status)
        .to receive(:code)
        .and_return('bogus')
    end

    it 'is invalid' do
      expect_valid(false, status: %i(inclusion))
    end
  end

  context 'if the user lacks permission' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  describe 'assignable_values' do
    context 'for project' do
      before do
        assignable_parents
      end

      it 'returns all projects the user has the add_subprojects permissions for' do
        expect(contract.assignable_parents)
          .to eql assignable_parents
      end
    end

    context 'for a list custom field' do
      let(:custom_field) { FactoryBot.build_stubbed(:list_project_custom_field) }

      it 'is the list of custom field values' do
        expect(subject.assignable_custom_field_values(custom_field))
          .to eql custom_field.possible_values
      end
    end

    context 'for a version custom field' do
      let(:custom_field) { FactoryBot.build_stubbed(:version_project_custom_field) }
      let(:versions) { double('versions') }

      before do
        allow(project)
          .to receive(:assignable_versions)
          .and_return(versions)
      end

      it 'is the list of versions for the project' do
        expect(subject.assignable_custom_field_values(custom_field))
          .to eql versions
      end
    end
  end

  describe 'available_custom_fields' do
    let(:visible_custom_field) { FactoryBot.build_stubbed(:int_project_custom_field, visible: true) }
    let(:invisible_custom_field) { FactoryBot.build_stubbed(:int_project_custom_field, visible: false) }

    before do
      allow(project)
        .to receive(:available_custom_fields)
        .and_return([visible_custom_field, invisible_custom_field])
    end

    context 'if the user is admin' do
      before do
        allow(current_user)
          .to receive(:admin?)
          .and_return(true)
      end

      it 'returns all available_custom_fields of the project' do
        expect(subject.available_custom_fields)
          .to match_array([visible_custom_field, invisible_custom_field])
      end
    end

    context 'if the user is no admin' do
      it 'returns all visible and available_custom_fields of the project' do
        expect(subject.available_custom_fields)
          .to match_array([visible_custom_field])
      end
    end
  end
end
