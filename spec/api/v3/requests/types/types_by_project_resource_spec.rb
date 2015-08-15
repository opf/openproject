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
require 'rack/test'

describe '/api/v3/projects/:id/types' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:project) { FactoryGirl.create(:project, no_types: true, is_public: false) }
  let(:requested_project) { project }
  let(:current_user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  let!(:irrelevant_types) { FactoryGirl.create_list(:type, 4) }
  let!(:expected_types) { FactoryGirl.create_list(:type, 4) }

  describe '#get' do
    let(:get_path) { api_v3_paths.types_by_project requested_project.id }
    subject(:response) { last_response }

    before do
      project.types << expected_types
    end

    context 'logged in user' do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      it_behaves_like 'API V3 collection response', 4, 4, 'Type'

      it 'only contains expected types' do
        actual_types = JSON.parse(subject.body)['_embedded']['elements']
        actual_type_ids = actual_types.map { |hash| hash['id'] }
        expected_type_ids = expected_types.map(&:id)

        expect(actual_type_ids).to match_array expected_type_ids
      end

      # N.B. this test depends on order, while this is not strictly neccessary
      it 'only contains expected types' do
        (0..3).each do |i|
          expected_id = expected_types[i].id.to_json
          expect(subject.body).to be_json_eql(expected_id).at_path("_embedded/elements/#{i}/id")
        end
      end

      context 'in a foreign project' do
        let(:requested_project) { FactoryGirl.create(:project, is_public: false) }

        it_behaves_like 'not found'
      end
    end

    context 'not logged in user' do
      before do
        get get_path
      end

      it_behaves_like 'not found'
    end
  end
end
