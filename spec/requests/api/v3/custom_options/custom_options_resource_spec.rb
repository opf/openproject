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
require 'rack/test'

describe 'API v3 Custom Options resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:custom_field) do
    cf = FactoryBot.create(:list_wp_custom_field)

    project.work_package_custom_fields << cf

    cf
  end
  let(:custom_option) do
    FactoryBot.create(:custom_option,
                       custom_field: custom_field)
  end

  subject(:response) { last_response }

  describe 'GET api/v3/custom_options/:id' do
    let(:path) { api_v3_paths.custom_option custom_option.id }

    before do
      allow(User)
        .to receive(:current)
        .and_return(user)
      get path
    end

    context 'when being allowed' do
      it 'is successful' do
        expect(subject.status)
          .to eql(200)
      end

      it 'returns the custom option' do
        expect(response.body)
          .to be_json_eql('CustomOption'.to_json)
          .at_path('_type')

        expect(response.body)
          .to be_json_eql(custom_option.id.to_json)
          .at_path('id')

        expect(response.body)
          .to be_json_eql(custom_option.value.to_json)
          .at_path('value')
      end
    end

    context 'when lacking permission' do
      let(:permissions) { [] }

      it 'is 404' do
        expect(subject.status)
          .to eql(404)
      end
    end

    context 'when custom option not in project' do
      let(:custom_field) do
        # not added to project
        FactoryBot.create(:list_wp_custom_field)
      end

      it 'is 404' do
        expect(subject.status)
          .to eql(404)
      end
    end

    context 'when not existing' do
      let(:path) { api_v3_paths.custom_option 0 }

      it 'is 404' do
        expect(subject.status)
          .to eql(404)
      end
    end
  end
end
