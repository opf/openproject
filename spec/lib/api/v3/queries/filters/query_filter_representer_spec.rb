#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::Filters::QueryFilterRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:filter) { Queries::WorkPackages::Filter::SubjectFilter.new }
  let(:representer) { described_class.new(filter) }

  subject { representer.to_json }

  describe 'generation' do
    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.query_filter 'subject' }
        let(:title) { 'Subject' }
      end
    end

    it 'has _type QueryFilter' do
      is_expected
        .to be_json_eql('QueryFilter'.to_json)
        .at_path('_type')
    end

    it 'has id attribute' do
      is_expected
        .to be_json_eql('subject'.to_json)
        .at_path('id')
    end

    context 'for a translated filter' do
      let(:filter) { Queries::WorkPackages::Filter::AssignedToFilter.new }

      describe '_links' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { api_v3_paths.query_filter 'assignee' }
          let(:title) { 'Assignee' }
        end
      end

      it 'has id attribute' do
        is_expected
          .to be_json_eql('assignee'.to_json)
          .at_path('id')
      end
    end

    context 'for a custom field filter' do
      let(:custom_field) { FactoryGirl.build_stubbed(:list_wp_custom_field) }
      let(:filter) { Queries::WorkPackages::Filter::CustomFieldFilter.new }

      before do
        allow(WorkPackageCustomField)
          .to receive(:find_by_id)
          .with(custom_field.id)
          .and_return custom_field

        filter.name = "cf_#{custom_field.id}"
      end

      describe '_links' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { api_v3_paths.query_filter "customField#{custom_field.id}" }
          let(:title) { custom_field.name }
        end
      end

      it 'has id attribute' do
        is_expected
          .to be_json_eql("customField#{custom_field.id}".to_json)
          .at_path('id')
      end
    end
  end
end
