#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter do
  let(:custom_field) { FactoryGirl.build(:custom_field) }
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: work_package.project)
  }
  let(:schema) {
    ::API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package: work_package)
  }
  let(:embedded) { false }
  let(:representer) {
    described_class.create(schema,
                           form_embedded: embedded,
                           current_user: current_user)
  }
  subject { representer.to_json }

  shared_examples_for 'has a collection of allowed values' do
    let(:embedded) { true }

    before do
      allow(schema).to receive(:assignable_values).and_return(nil)
    end

    context 'when no values are allowed' do
      before do
        allow(schema).to receive(:assignable_values).with(factory, anything).and_return([])
      end

      it_behaves_like 'links to and embeds allowed values directly' do
        let(:path) { json_path }
        let(:hrefs) { [] }
      end
    end

    context 'when values are allowed' do
      let(:values) { FactoryGirl.build_stubbed_list(factory, 3) }

      before do
        allow(schema).to receive(:assignable_values).with(factory, anything).and_return(values)
      end

      it_behaves_like 'links to and embeds allowed values directly' do
        let(:path) { json_path }
        let(:hrefs) { values.map { |value| "/api/v3/#{href_path}/#{value.id}" } }
      end
    end

    context 'when not embedded' do
      before do
        allow(schema).to receive(:assignable_values).with(factory, anything).and_return(nil)
      end

      it_behaves_like 'does not link to allowed values' do
        let(:path) { json_path }
      end
    end
  end

  describe 'spentTime' do
    shared_examples_for 'spentTime visible' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'spentTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('activerecord.attributes.work_package.spent_time') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    shared_examples_for 'spentTime not visible' do
      it { is_expected.not_to have_json_path('spentTime') }
    end

    let(:can_view_time_entries) { false }
    let(:can_view_own_time_entries) { false }

    before do
      allow(current_user).to receive(:allowed_to?).and_return(false)
      allow(current_user).to receive(:allowed_to?).with(:view_time_entries, work_package.project)
        .and_return can_view_time_entries
      allow(current_user).to receive(:allowed_to?).with(:view_own_time_entries, work_package.project)
        .and_return can_view_own_time_entries
    end

    context 'costs enabled' do
      before do
        allow(schema.project).to receive(:costs_enabled?).and_return true
      end

      context 'with no time entry permissions' do
        it_behaves_like 'spentTime not visible'
      end

      context 'with :view_time_entries permission' do
        let(:can_view_time_entries) { true }
        it_behaves_like 'spentTime visible'
      end

      context 'with :view_own_time_entries permission' do
        let(:can_view_own_time_entries) { true }
        it_behaves_like 'spentTime visible'
      end
    end

    context 'costs disabled' do
      before do
        allow(schema.project).to receive(:costs_enabled?).and_return false
      end

      context 'with no time entry permissions' do
        it_behaves_like 'spentTime not visible'
      end

      context 'with :view_time_entries permission' do
        let(:can_view_time_entries) { true }
        it_behaves_like 'spentTime visible'
      end

      context 'with :view_own_time_entries permission' do
        let(:can_view_own_time_entries) { true }
        it_behaves_like 'spentTime not visible'
      end
    end
  end

  describe 'overallCosts' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'overallCosts' }
      let(:type) { 'String' }
      let(:name) { I18n.t('activerecord.attributes.work_package.overall_costs') }
      let(:required) { false }
      let(:writable) { false }
    end

    context 'costs disabled' do
      before do
        allow(schema.project).to receive(:costs_enabled?).and_return(false)
      end

      it 'has no schema for overallCosts' do
        is_expected.not_to have_json_path('overallCosts')
      end
    end
  end

  describe 'costsByType' do
    shared_examples_for 'costsByType visible' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'costsByType' }
        let(:type) { 'Collection' }
        let(:name) { I18n.t('activerecord.attributes.work_package.spent_units') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    shared_examples_for 'costsByType not visible' do
      it { is_expected.not_to have_json_path('costsByType') }
    end

    let(:can_view_cost_entries) { false }
    let(:can_view_own_cost_entries) { false }

    before do
      allow(current_user).to receive(:allowed_to?).and_return(false)
      allow(current_user).to receive(:allowed_to?).with(:view_cost_entries, work_package.project)
        .and_return can_view_cost_entries
      allow(current_user).to receive(:allowed_to?).with(:view_own_cost_entries, work_package.project)
        .and_return can_view_own_cost_entries
    end

    context 'costs disabled, but all permissions' do
      let(:can_view_cost_entries) { true }
      let(:can_view_own_cost_entries) { true }

      before do
        allow(schema.project).to receive(:costs_enabled?).and_return(false)
      end

      it_behaves_like 'costsByType not visible'
    end

    context 'costs enabled' do
      context 'no permissions' do
        it_behaves_like 'costsByType not visible'
      end

      context 'can only view own cost entries' do
        let(:can_view_own_cost_entries) { true }
        it_behaves_like 'costsByType visible'
      end

      context 'can view all cost entries' do
        let(:can_view_cost_entries) { true }
        it_behaves_like 'costsByType visible'
      end
    end
  end

  describe 'budget' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'costObject' }
      let(:type) { 'Budget' }
      let(:name) { I18n.t('attributes.cost_object') }
      let(:required) { false }
      let(:writable) { true }
    end

    it_behaves_like 'has a collection of allowed values' do
      let(:json_path) { 'costObject' }
      let(:href_path) { 'budgets' }
      let(:factory) { :cost_object }
    end

    context 'costs disabled' do
      before do
        allow(schema.project).to receive(:costs_enabled?).and_return(false)
      end

      it 'has no schema for budget' do
        is_expected.not_to have_json_path('costObject')
      end
    end
  end
end
