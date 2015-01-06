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

describe ::API::V3::Versions::VersionRepresenter do
  let(:version) { FactoryGirl.build_stubbed(:version) }
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:representer) { described_class.new(version, current_user: user) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('Version'.to_json).at_path('_type') }

    context 'links' do

      it { should have_json_type(Object).at_path('_links') }

      it 'to self' do
        path = api_v3_paths.version(version.id)

        expect(subject).to be_json_eql(path.to_json).at_path('_links/self/href')
      end

      context 'to the defining project' do
        let(:path) { api_v3_paths.project(version.project.id) }

        it 'exists if the user has the permission to see the project' do
          allow(version.project).to receive(:visible?).with(user).and_return(true)

          subject = representer.to_json

          expect(subject).to be_json_eql(path.to_json).at_path('_links/definingProject/href')
        end

        it 'does not exist if the user lacks the permission to see the project' do
          allow(version.project).to receive(:visible?).with(user).and_return(false)

          subject = representer.to_json

          expect(subject).to_not have_json_path('_links/definingProject/href')
        end
      end

      it 'to available projects' do
        path = api_v3_paths.versions_projects(version.project.id)

        expect(subject).to be_json_eql(path.to_json).at_path('_links/availableInProjects/href')
      end
    end

    describe 'version' do
      it { is_expected.to be_json_eql(version.id.to_json).at_path('id') }
      it { is_expected.to be_json_eql(version.name.to_json).at_path('name') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'plain' }
        let(:raw) { version.description }
      end

      it { is_expected.to be_json_eql(version.start_date.to_json).at_path('startDate') }
      it { is_expected.to be_json_eql(version.due_date.to_json).at_path('endDate') }
      it { is_expected.to be_json_eql(version.status.to_json).at_path('status') }
      it { is_expected.to be_json_eql(version.created_on.to_json).at_path('createdAt') }
      it { is_expected.to be_json_eql(version.updated_on.to_json).at_path('updatedAt') }
    end
  end
end
