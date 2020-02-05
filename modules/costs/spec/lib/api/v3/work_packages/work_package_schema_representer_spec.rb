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

describe ::API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter do
  let(:custom_field) { FactoryBot.build(:custom_field) }
  let(:work_package) { FactoryBot.build_stubbed(:stubbed_work_package) }
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?)
        .and_return(false)
      allow(u)
        .to receive(:allowed_to?)
        .with(:edit_work_packages, work_package.project, global: false)
        .and_return(true)
    end
  end
  let(:schema) do
    ::API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package: work_package)
  end
  let(:embedded) { false }
  let(:representer) do
    described_class.create(schema,
                           nil,
                           form_embedded: embedded,
                           current_user: current_user)
  end
  let(:project) { work_package.project }

  subject { representer.to_json }

  before do
    login_as(current_user)
  end

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
      let(:values) { FactoryBot.build_stubbed_list(factory, 3) }

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

  describe 'overallCosts' do
    context 'has the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'overallCosts' }
        let(:type) { 'String' }
        let(:name) { I18n.t('activerecord.attributes.work_package.overall_costs') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context 'lacks the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path('overallCosts') }
    end
  end

  describe 'laborCosts' do
    context 'has the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'laborCosts' }
        let(:type) { 'String' }
        let(:name) { I18n.t('activerecord.attributes.work_package.labor_costs') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context 'lacks the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path('laborCosts') }
    end
  end

  describe 'materialCosts' do
    context 'has the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'materialCosts' }
        let(:type) { 'String' }
        let(:name) { I18n.t('activerecord.attributes.work_package.material_costs') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context 'lacks the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path('materialCosts') }
    end
  end

  describe 'costsByType' do
    context 'has the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'costsByType' }
        let(:type) { 'Collection' }
        let(:name) { I18n.t('activerecord.attributes.work_package.spent_units') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context 'lacks the permissions' do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path('costsByType') }
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
