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
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: work_package.project)
  }
  let(:schema) {
    ::API::V3::WorkPackages::Schema::WorkPackageSchema.new(work_package: work_package)
  }
  let(:representer)  { described_class.new(schema, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    shared_examples_for 'has basic schema properties' do
      it 'exists' do
        is_expected.to have_json_path(path)
      end

      it 'has a type' do
        is_expected.to be_json_eql(type.to_json).at_path("#{path}/type")
      end

      it 'has a name' do
        is_expected.to be_json_eql(name.to_json).at_path("#{path}/name")
      end

      it 'indicates if it is required' do
        is_expected.to be_json_eql(required.to_json).at_path("#{path}/required")
      end

      it 'indicates if it is writable' do
        is_expected.to be_json_eql(writable.to_json).at_path("#{path}/writable")
      end
    end

    shared_examples_for 'links to allowed values directly' do
      it 'has the expected number of links' do
        is_expected.to have_json_size(hrefs.size).at_path("#{path}/_links/allowedValues")
      end

      it 'contains links to the allowed values' do
        index = 0
        hrefs.each do |href|
          href_path = "#{path}/_links/allowedValues/#{index}/href"
          is_expected.to be_json_eql(href.to_json).at_path(href_path)
          index += 1
        end
      end

      it 'has the expected number of embedded values' do
        is_expected.to have_json_size(hrefs.size).at_path("#{path}/_embedded/allowedValues")
      end

      it 'embeds the allowed values' do
        index = 0
        hrefs.each do |href|
          href_path = "#{path}/_embedded/allowedValues/#{index}/_links/self/href"
          is_expected.to be_json_eql(href.to_json).at_path(href_path)
          index += 1
        end
      end
    end

    shared_examples_for 'links to allowed values via collection link' do
      it 'contains the link to the allowed values' do
        is_expected.to be_json_eql(href.to_json).at_path("#{path}/_links/allowedValues/href")
      end
    end

    describe '_type' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { '_type' }
        let(:type) { 'MetaType' }
        let(:name) { I18n.t('api_v3.attributes._type') }
        let(:required) { true }
        let(:writable) { false }
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
        let(:name) { I18n.t('activerecord.attributes.work_package.id') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'subject' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'subject' }
        let(:type) { 'String' }
        let(:name) { I18n.t('activerecord.attributes.work_package.subject') }
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
        let(:name) { I18n.t('activerecord.attributes.work_package.description') }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe 'startDate' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'startDate' }
        let(:type) { 'Date' }
        let(:name) { I18n.t('activerecord.attributes.work_package.start_date') }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe 'dueDate' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'dueDate' }
        let(:type) { 'Date' }
        let(:name) { I18n.t('activerecord.attributes.work_package.due_date') }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe 'estimatedTime' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'estimatedTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('activerecord.attributes.work_package.estimated_time') }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe 'spentTime' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'spentTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('activerecord.attributes.work_package.spent_time') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'percentageDone' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'percentageDone' }
        let(:type) { 'Integer' }
        let(:name) { I18n.t('activerecord.attributes.work_package.done_ratio') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'createdAt' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'createdAt' }
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('activerecord.attributes.work_package.created_at') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'updatedAt' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'updatedAt' }
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('activerecord.attributes.work_package.updated_at') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'author' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'author' }
        let(:type) { 'User' }
        let(:name) { I18n.t('activerecord.attributes.work_package.author') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'project' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'project' }
        let(:type) { 'Project' }
        let(:name) { I18n.t('activerecord.attributes.work_package.project') }
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
        let(:writable) { false }
      end
    end

    describe 'status' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'status' }
        let(:type) { 'Status' }
        let(:name) { I18n.t('activerecord.attributes.work_package.status') }
        let(:required) { true }
        let(:writable) { true }
      end

      context 'w/o allowed statuses' do
        before { allow(work_package).to receive(:new_statuses_allowed_to).and_return([]) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'status' }
          let(:hrefs) { [] }
        end
      end

      context 'with allowed statuses' do
        let(:statuses) { FactoryGirl.build_list(:status, 3) }

        before { allow(work_package).to receive(:new_statuses_allowed_to).and_return(statuses) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'status' }
          let(:hrefs) { statuses.map { |status| "/api/v3/statuses/#{status.id}" } }
        end
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

      context 'w/o allowed versions' do
        before { allow(work_package).to receive(:assignable_versions).and_return([]) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'version' }
          let(:hrefs) { [] }
        end
      end

      context 'with allowed versions' do
        let(:versions) { FactoryGirl.build_stubbed_list(:version, 3) }

        before { allow(work_package).to receive(:assignable_versions).and_return(versions) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'version' }
          let(:hrefs) { versions.map { |version| "/api/v3/versions/#{version.id}" } }
        end
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

      context 'w/o allowed priorities' do
        before { allow(work_package).to receive(:assignable_priorities).and_return([]) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'priority' }
          let(:hrefs) { [] }
        end
      end

      context 'with allowed priorities' do
        let(:priorities) { FactoryGirl.build_stubbed_list(:priority, 3) }

        before { allow(work_package).to receive(:assignable_priorities).and_return(priorities) }

        it_behaves_like 'links to allowed values directly' do
          let(:path) { 'priority' }
          let(:hrefs) { priorities.map { |priority| "/api/v3/priorities/#{priority.id}" } }
        end
      end
    end

    describe 'responsible and assignee' do
      let(:base_href) { "/api/v3/projects/#{work_package.project.id}" }

      describe 'assignee' do
        it_behaves_like 'has basic schema properties' do
          let(:path) { 'assignee' }
          let(:type) { 'User' }
          let(:name) { I18n.t('activerecord.attributes.work_package.assigned_to') }
          let(:required) { false }
          let(:writable) { true }
        end

        it_behaves_like 'links to allowed values via collection link' do
          let(:path) { 'assignee' }
          let(:href) { "#{base_href}/available_assignees" }
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
      end
    end
  end
end
