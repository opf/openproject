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

describe ::API::V3::WorkPackages::WorkPackagePayloadRepresenter do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    FactoryGirl.build(:work_package,
                      start_date: Date.today.to_datetime,
                      due_date: Date.today.to_datetime,
                      created_at: DateTime.now,
                      updated_at: DateTime.now)
  end
  let(:representer) { described_class.create(work_package) }

  before do allow(work_package).to receive(:lock_version).and_return(1) end

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe 'work_package' do
      it { is_expected.to have_json_path('subject') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'textile' }
        let(:raw) { work_package.description }
        let(:html) { '<p>' + work_package.description + '</p>' }
      end

      describe 'lock version' do
        it { is_expected.to have_json_path('lockVersion') }

        it { is_expected.to have_json_type(Integer).at_path('lockVersion') }

        it { is_expected.to be_json_eql(work_package.lock_version.to_json).at_path('lockVersion') }
      end

      describe 'estimated hours' do
        it { is_expected.to have_json_path('estimatedTime') }
        it do
          is_expected.to be_json_eql(work_package.estimated_hours.to_json)
            .at_path('estimatedTime')
        end

        context 'not set' do
          it { is_expected.to have_json_type(NilClass).at_path('estimatedTime') }
        end

        context 'set' do
          let(:work_package) { FactoryGirl.build(:work_package, estimated_hours: 0) }

          it { is_expected.to have_json_type(String).at_path('estimatedTime') }
        end
      end

      describe 'percentage done' do
        context 'percentage done enabled' do
          it { is_expected.to have_json_path('percentageDone') }
          it { is_expected.to have_json_type(Integer).at_path('percentageDone') }
          it do
            is_expected.to be_json_eql(work_package.done_ratio.to_json).at_path('percentageDone')
          end
        end

        context 'percentage done disabled' do
          before do allow(Setting).to receive(:work_package_done_ratio).and_return('disabled') end

          it { is_expected.to_not have_json_path('percentageDone') }
        end
      end

      describe 'startDate' do
        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { work_package.start_date }
          let(:json_path) { 'startDate' }
        end

        context 'no start date' do
          let(:work_package) { FactoryGirl.build(:work_package, start_date: nil) }

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('startDate')
          end
        end
      end

      describe 'dueDate' do
        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { work_package.due_date }
          let(:json_path) { 'dueDate' }
        end

        context 'no due date' do
          let(:work_package) { FactoryGirl.build(:work_package, due_date: nil) }

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('dueDate')
          end
        end
      end
    end

    describe '_links' do
      it { is_expected.to have_json_path('_links') }

      let(:path) { "_links/#{property}/href" }

      shared_examples_for 'linked property' do
        before do
          unless defined?(link) && defined?(property)
            raise "Requires to have 'property' and 'link' defined"
          end
        end

        it { expect(subject).to be_json_eql(link.to_json).at_path(path) }
      end

      describe 'status' do
        let(:status) { FactoryGirl.build_stubbed(:status) }

        before do work_package.status = status end

        it_behaves_like 'linked property' do
          let(:property) { 'status' }
          let(:link) { "/api/v3/statuses/#{status.id}" }
        end
      end

      describe 'assignee and responsible' do
        let(:user) { FactoryGirl.build_stubbed(:user) }
        let(:link) { "/api/v3/users/#{user.id}" }

        describe 'assignee' do
          before do work_package.assigned_to = user end

          it_behaves_like 'linked property' do
            let(:property) { 'assignee' }
          end
        end

        describe 'responsible' do
          before do work_package.responsible = user end

          it_behaves_like 'linked property' do
            let(:property) { 'responsible' }
          end
        end
      end

      describe 'version' do
        let(:version) { FactoryGirl.build_stubbed(:version) }

        before do work_package.fixed_version = version end

        it_behaves_like 'linked property' do
          let(:property) { 'version' }
          let(:link) { "/api/v3/versions/#{version.id}" }
        end
      end

      describe 'category' do
        let(:category) { FactoryGirl.build_stubbed(:category) }

        before do work_package.category = category end

        it_behaves_like 'linked property' do
          let(:property) { 'category' }
          let(:link) { "/api/v3/categories/#{category.id}" }
        end
      end

      describe 'priority' do
        let(:priority) { FactoryGirl.build_stubbed(:priority) }

        before do work_package.priority = priority end

        it_behaves_like 'linked property' do
          let(:property) { 'priority' }
          let(:link) { "/api/v3/priorities/#{priority.id}" }
        end
      end

      describe 'parent' do
        let(:parent) { FactoryGirl.build_stubbed(:work_package) }

        before do work_package.parent = parent end

        it_behaves_like 'linked property' do
          let(:property) { 'parent' }
          let(:link) { "/api/v3/work_packages/#{parent.id}" }
        end
      end
    end

    describe 'custom fields' do
      it 'uses a CustomFieldInjector' do
        expected_method = :create_value_representer_for_property_patching
        expect(::API::V3::Utilities::CustomFieldInjector).to receive(expected_method)
          .and_call_original
        representer.to_json
      end
    end
  end

  describe 'parsing' do
    let(:attributes) { {} }
    let(:links) { {} }
    let(:json) do
      copy = attributes.clone
      copy[:_links] = links
      copy.to_json
    end

    subject { representer.from_json(json) }

    shared_examples_for 'settable ISO 8601 date only' do
      let(:attributes) do
        {
          property => dateString
        }
      end

      context 'with an ISO formatted date' do
        let(:dateString) { '2015-01-31' }

        it 'sets the date' do
          expect(subject.send(method)).to eql(Date.new(2015, 1, 31))
        end
      end

      context 'with null' do
        let(:dateString) { nil }

        it 'sets the date to nil' do
          expect(subject.send(method)).to eql(nil)
        end
      end

      context 'with a non ISO formatted date' do
        let(:dateString) { '31.01.2015' }

        it 'raises an error' do
          expect { subject }.to raise_error(API::Errors::PropertyFormatError)
        end
      end

      context 'with an ISO formatted date and time' do
        let(:dateString) { '2015-01-31T13:37:00Z' }

        it 'raises an error' do
          expect { subject }.to raise_error(API::Errors::PropertyFormatError)
        end
      end
    end

    describe 'startDate' do
      it_behaves_like 'settable ISO 8601 date only' do
        let(:property) { :startDate }
        let(:method) { :start_date }
      end
    end

    describe 'dueDate' do
      it_behaves_like 'settable ISO 8601 date only' do
        let(:property) { :dueDate }
        let(:method) { :due_date }
      end
    end

    shared_examples_for 'linked resource' do
      let(:path) { api_v3_paths.send(attribute_name, id) }
      let(:association_name) { attribute_name + '_id' }
      let(:id) { work_package.send(association_name) + 1 }
      let(:links) {
        Hash.new.tap do |h|
          h[attribute_name] = href
        end
      }
      let(:representer_attribute) { subject.send(association_name) }

      describe 'with a valid href' do
        let(:href) { { href: path } }

        it 'sets attribute to the specified id' do
          expect(representer_attribute).to eql(id)
        end
      end

      describe 'with a null href' do
        let(:href) { { href: nil } }

        it 'sets attribute to nil' do
          expect(representer_attribute).to eql(nil)
        end
      end

      describe 'with an invalid link' do
        let(:href) { {} }
        !let(:old_id) { work_package.send(association_name) }

        it 'leaves attribute unchanged' do
          expect(representer_attribute).to eql(old_id)
        end
      end
    end

    describe 'project' do
      it_behaves_like 'linked resource' do
        let(:attribute_name) { 'project' }
      end
    end

    describe 'version' do
      before do
        work_package.fixed_version_id = 1
      end

      it_behaves_like 'linked resource' do
        let(:attribute_name) { 'version' }
        let(:association_name) { 'fixed_version_id' }
      end
    end

    describe 'type' do
      it_behaves_like 'linked resource' do
        let(:attribute_name) { 'type' }
      end
    end

    describe 'status' do
      it_behaves_like 'linked resource' do
        let(:attribute_name) { 'status' }
      end
    end

    describe 'assignee' do
      before do
        work_package.assigned_to_id = 1
      end

      it_behaves_like 'linked resource' do
        let(:path) { api_v3_paths.user(id) }
        let(:attribute_name) { 'assignee' }
        let(:association_name) { 'assigned_to_id' }
      end
    end

    describe 'responsible' do
      before do
        work_package.responsible_id = 1
      end

      it_behaves_like 'linked resource' do
        let(:path) { api_v3_paths.user(id) }
        let(:attribute_name) { 'responsible' }
      end
    end

    describe 'category' do
      before do
        work_package.category_id = 1
      end

      it_behaves_like 'linked resource' do
        let(:attribute_name) { 'category' }
      end
    end

    describe 'parent' do
      before do
        work_package.parent_id = 1
      end

      it_behaves_like 'linked resource' do
        let(:path) { api_v3_paths.work_package(id) }
        let(:attribute_name) { 'parent' }
      end
    end
  end
end
