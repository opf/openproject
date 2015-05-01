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

describe 'api/v2/versions/index.api.rabl', type: :view do
  let(:shared_with) { [42, 1, 2, 3] }
  let(:version) {
    Api::V2::VersionsController::Version.new(42,
                                             'My Version',
                                             'Some description',
                                             43,
                                             'locked',
                                             Date.today,
                                             Date.today + 1,
                                             shared_with)
  }

  before { params[:format] = 'json' }

  shared_context 'assign versions and render' do
    before do
      assign(:versions, versions)

      render
    end
  end

  describe 'no versions' do
    include_context 'assign versions and render' do
      let(:versions) { [] }
    end

    it { expect(response).to have_json_size(0).at_path('versions') }
  end

  describe 'with versions' do
    let(:versions) { [version] }

    include_context 'assign versions and render'

    it { expect(response).to have_json_size(1).at_path('versions') }

    describe 'paths' do
      it { expect(response).to have_json_path('versions/0/id') }

      it { expect(response).to have_json_path('versions/0/name') }

      it { expect(response).to have_json_path('versions/0/description') }

      it { expect(response).to have_json_path('versions/0/status') }

      it { expect(response).to have_json_path('versions/0/start_date') }

      it { expect(response).to have_json_path('versions/0/effective_date') }

      it { expect(response).to have_json_path('versions/0/defining_project_id') }

      it { expect(response).to have_json_path('versions/0/applies_to_project_ids') }
    end

    describe 'content' do
      subject { parse_json(response)['versions'][0] }

      it { expect(subject['id']).to eql(version.id) }

      it { expect(subject['name']).to eql(version.name) }

      it { expect(subject['description']).to eql(version.description) }

      it { expect(subject['status']).to eql(version.status) }

      it { expect(subject['start_date']).to eql(version.start_date.iso8601) }

      it { expect(subject['effective_date']).to eql(version.effective_date.iso8601) }

      it { expect(subject['applies_to_project_ids']).to eql(shared_with) }
    end
  end

  describe 'many versions' do
    let(:versions) { [version, version, version] }

    include_context 'assign versions and render'

    it { expect(response).to have_json_size(3).at_path('versions') }
  end
end
