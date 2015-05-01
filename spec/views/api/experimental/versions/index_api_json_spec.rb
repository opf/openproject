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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/experimental/versions/index.api.rabl', type: :view do
  let(:project_a) { FactoryGirl.build_stubbed(:project) }
  let(:project_b) { FactoryGirl.build_stubbed(:project) }
  let(:version_1)   { FactoryGirl.build_stubbed(:version, project: project_a) }
  let(:version_2)   { FactoryGirl.build_stubbed(:version, project: project_a) }

  before do
    params[:format] = 'json'

    assign(:versions, versions)
  end

  subject { response.body }

  describe 'with no versions available' do
    let(:versions) { [] }

    before do
      render
    end

    it { is_expected.to have_json_path('versions') }
    it { is_expected.to have_json_size(0).at_path('versions') }
  end

  describe 'with 2 versions of the project' do
    let(:versions) { [version_1, version_2] }
    let(:version_1_json) { { id: version_1.id, name: version_1.name }.to_json }
    let(:version_2_json) { { id: version_2.id, name: version_2.name }.to_json }

    before do
      assign(:project, project_a)
      render
    end

    it { is_expected.to have_json_path('versions') }
    it { is_expected.to have_json_size(2).at_path('versions') }

    it { is_expected.to have_json_type(Object).at_path('versions/1') }
    it { is_expected.to include_json(version_1_json).at_path('versions') }
    it { is_expected.to include_json(version_2_json).at_path('versions') }
  end

  describe 'with a version that is in a different project' do
    let(:versions)  { [version_1] }
    let(:version_1_json) { { id: version_1.id, name: version_1.to_s_with_project }.to_json }

    before do
      assign(:project, project_b)
      render
    end

    it { is_expected.to have_json_path('versions') }
    it { is_expected.to have_json_size(1).at_path('versions') }
    it { is_expected.to include_json(version_1_json).at_path('versions') }
  end
end
