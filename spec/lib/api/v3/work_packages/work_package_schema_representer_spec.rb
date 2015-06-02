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
  include API::V3::Utilities::PathHelper

  let(:custom_field) { FactoryGirl.build(:custom_field) }
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: work_package.project)
  }
  let(:schema) {
    ::API::V3::WorkPackages::Schema::WorkPackageSchema.new(work_package: work_package)
  }
  let(:embedded) { false }
  let(:representer) {
    described_class.create(schema,
                           form_embedded: embedded,
                           current_user: current_user)
  }

  context 'generation' do
    subject(:generated) { representer.to_json }

    shared_examples_for 'has a collection of allowed values' do
      let(:embedded) { true }

      context 'when no values are allowed' do
        before { allow(schema).to receive(allowed_values_method).and_return([]) }

        it_behaves_like 'links to and embeds allowed values directly' do
          let(:path) { json_path }
          let(:hrefs) { [] }
        end
      end

      context 'when values are allowed' do
        let(:values) { FactoryGirl.build_stubbed_list(factory, 3) }

        before { allow(schema).to receive(allowed_values_method).and_return(values) }

        it_behaves_like 'links to and embeds allowed values directly' do
          let(:path) { json_path }
          let(:hrefs) { values.map { |value| "/api/v3/#{href_path}/#{value.id}" } }
        end
      end

      context 'when not embedded' do
        let(:embedded) { false }

        it_behaves_like 'does not link to allowed values' do
          let(:path) { json_path }
        end
      end
    end

    describe '_type' do
      it 'is indicated as Schema' do
        is_expected.to be_json_eql('Schema'.to_json).at_path('_type')
      end
    end

    describe 'lock version' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'lockVersion' }
        let(:type) { 'Integer' }
        let(:name) { I18n.t('api_v3.attributes.lock_version') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'id' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'id' }
        let(:type) { 'Integer' }
        let(:name) { I18n.t('attributes.id') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'subject' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'subject' }
        let(:type) { 'String' }
        let(:name) { I18n.t('attributes.subject') }
        let(:required) { true }
        let(:writable) { true }
      end

      it 'indicates its minimum length' do
        is_expected.to be_json_eql(1.to_json).at_path('subject/minLength')
      end

      it 'indicates its maximum length' do
        is_expected.to be_json_eql(255.to_json).at_path('subject/maxLength')
      end
    end

    describe 'description' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'description' }
        let(:type) { 'Formattable' }
        let(:name) { I18n.t('attributes.description') }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe 'startDate' do
      before do
        allow(schema).to receive(:start_date_writable?).and_return true
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'startDate' }
        let(:type) { 'Date' }
        let(:name) { I18n.t('attributes.start_date') }
        let(:required) { false }
        let(:writable) { true }
      end

      context 'not writable' do
        before do
          allow(schema).to receive(:start_date_writable?).and_return false
        end

        it_behaves_like 'has basic schema properties' do
          let(:path) { 'startDate' }
          let(:type) { 'Date' }
          let(:name) { I18n.t('attributes.start_date') }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe 'dueDate' do
      before do
        allow(schema).to receive(:due_date_writable?).and_return true
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'dueDate' }
        let(:type) { 'Date' }
        let(:name) { I18n.t('attributes.due_date') }
        let(:required) { false }
        let(:writable) { true }
      end

      context 'not writable' do
        before do
          allow(schema).to receive(:due_date_writable?).and_return false
        end

        it_behaves_like 'has basic schema properties' do
          let(:path) { 'dueDate' }
          let(:type) { 'Date' }
          let(:name) { I18n.t('attributes.due_date') }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe 'estimatedTime' do
      before do
        allow(schema).to receive(:estimated_time_writable?).and_return true
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'estimatedTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('attributes.estimated_time') }
        let(:required) { false }
        let(:writable) { true }
      end

      context 'not writable' do
        before do
          allow(schema).to receive(:estimated_time_writable?).and_return false
        end

        it_behaves_like 'has basic schema properties' do
          let(:path) { 'estimatedTime' }
          let(:type) { 'Duration' }
          let(:name) { I18n.t('attributes.estimated_time') }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe 'spentTime' do
      before do
        # don't fail the test for other allowed_to calls than the expected ones
        allow(current_user).to receive(:allowed_to?).and_return false

        allow(current_user).to receive(:allowed_to?).with(:view_time_entries, work_package.project)
          .and_return true
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'spentTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('activerecord.attributes.work_package.spent_time') }
        let(:required) { true }
        let(:writable) { false }
      end

      context 'not allowed to view time entries' do
        before do
          allow(current_user).to receive(:allowed_to?).with(:view_time_entries,
                                                            work_package.project)
            .and_return false
        end

        it 'does not show spentTime' do
          is_expected.not_to have_json_path('spentTime')
        end
      end
    end

    describe 'percentageDone' do
      before do
        allow(schema).to receive(:percentage_done_writable?).and_return true
      end

      it_behaves_like 'has basic schema properties' do
        let(:path) { 'percentageDone' }
        let(:type) { 'Integer' }
        let(:name) { I18n.t('activerecord.attributes.work_package.done_ratio') }
        let(:required) { true }
        let(:writable) { true }
      end

      context 'not writable' do
        before do
          allow(schema).to receive(:percentage_done_writable?).and_return false
        end

        it_behaves_like 'has basic schema properties' do
          let(:path) { 'percentageDone' }
          let(:type) { 'Integer' }
          let(:name) { I18n.t('activerecord.attributes.work_package.done_ratio') }
          let(:required) { true }
          let(:writable) { false }
        end
      end

      context 'is disabled' do
        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')
        end

        it 'is hidden' do
          is_expected.to_not have_json_path('percentageDone')
        end
      end
    end

    describe 'createdAt' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'createdAt' }
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('attributes.created_at') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'updatedAt' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'updatedAt' }
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('attributes.updated_at') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'author' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'author' }
        let(:type) { 'User' }
        let(:name) { I18n.t('attributes.author') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'project' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'project' }
        let(:type) { 'Project' }
        let(:name) { I18n.t('attributes.project') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'type' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'type' }
        let(:type) { 'Type' }
        let(:name) { I18n.t('activerecord.attributes.work_package.type') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'has a collection of allowed values' do
        let(:json_path) { 'type' }
        let(:href_path) { 'types' }
        let(:factory) { :type }
        let(:allowed_values_method) { :assignable_types }
      end
    end

    describe 'status' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'status' }
        let(:type) { 'Status' }
        let(:name) { I18n.t('attributes.status') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'has a collection of allowed values' do
        let(:json_path) { 'status' }
        let(:href_path) { 'statuses' }
        let(:factory) { :status }
        let(:allowed_values_method) { :assignable_statuses_for }
      end
    end

    describe 'categories' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'category' }
        let(:type) { 'Category' }
        let(:name) { I18n.t('attributes.category') }
        let(:required) { false }
        let(:writable) { true }
      end

      it_behaves_like 'has a collection of allowed values' do
        let(:json_path) { 'category' }
        let(:href_path) { 'categories' }
        let(:factory) { :category }
        let(:allowed_values_method) { :assignable_categories }
      end
    end

    describe 'versions' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'version' }
        let(:type) { 'Version' }
        let(:name) { I18n.t('activerecord.attributes.work_package.fixed_version') }
        let(:required) { false }
        let(:writable) { true }
      end

      it_behaves_like 'has a collection of allowed values' do
        let(:json_path) { 'version' }
        let(:href_path) { 'versions' }
        let(:factory) { :version }
        let(:allowed_values_method) { :assignable_versions }
      end
    end

    describe 'priorities' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'priority' }
        let(:type) { 'Priority' }
        let(:name) { I18n.t('activerecord.attributes.work_package.priority') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'has a collection of allowed values' do
        let(:json_path) { 'priority' }
        let(:href_path) { 'priorities' }
        let(:factory) { :priority }
        let(:allowed_values_method) { :assignable_priorities }
      end
    end

    describe 'responsible and assignee' do
      let(:embedded) { true }

      let(:base_href) { "/api/v3/projects/#{work_package.project.id}" }

      describe 'assignee' do
        it_behaves_like 'has basic schema properties' do
          let(:path) { 'assignee' }
          let(:type) { 'User' }
          let(:name) { I18n.t('attributes.assigned_to') }
          let(:required) { false }
          let(:writable) { true }
        end

        it_behaves_like 'links to allowed values via collection link' do
          let(:path) { 'assignee' }
          let(:href) { "#{base_href}/available_assignees" }
        end

        context 'when not embedded' do
          let(:embedded) { false }

          it_behaves_like 'does not link to allowed values' do
            let(:path) { 'assignee' }
          end
        end
      end

      describe 'responsible' do
        it_behaves_like 'has basic schema properties' do
          let(:path) { 'responsible' }
          let(:type) { 'User' }
          let(:name) { I18n.t('activerecord.attributes.work_package.responsible') }
          let(:required) { false }
          let(:writable) { true }
        end

        it_behaves_like 'links to allowed values via collection link' do
          let(:path) { 'responsible' }
          let(:href) { "#{base_href}/available_responsibles" }
        end

        context 'when not embedded' do
          let(:embedded) { false }

          it_behaves_like 'does not link to allowed values' do
            let(:path) { 'responsible' }
          end
        end
      end
    end

    describe 'custom fields' do
      it 'uses a CustomFieldInjector' do
        expect(::API::V3::Utilities::CustomFieldInjector).to receive(:create_schema_representer)
          .and_call_original
        representer.to_json
      end
    end
  end
end
