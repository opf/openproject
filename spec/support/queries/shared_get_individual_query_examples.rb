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

shared_examples_for 'GET individual query' do
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:filter) { [] }
  let(:path) do
    if filter.any?
      params = URI.encode(JSON.dump(filter))
      "#{base_path}?filters=#{params}"
    else
      base_path
    end
  end

  before do
    work_package
    get path
  end

  it 'should succeed' do
    expect(last_response.status).to eq(200)
  end

  it 'has the right endpoint set for the self reference' do
    expect(last_response.body)
      .to be_json_eql(path.to_json)
      .at_path('_links/self/href')
  end

  it 'embedds the query results' do
    expect(last_response.body)
      .to be_json_eql('WorkPackageCollection'.to_json)
      .at_path('_embedded/results/_type')
    expect(last_response.body)
      .to be_json_eql(api_v3_paths.work_package(work_package.id).to_json)
      .at_path('_embedded/results/_embedded/elements/0/_links/self/href')
  end

  context 'when providing a valid filters' do
    let(:filter) do
      [
        {
          "status": {
            "operator": "c",
            "values": []
          }
        }
      ]
    end

    it 'uses the provided filter' do
      expect(last_response.body)
        .to be_json_eql(0.to_json)
        .at_path('_embedded/results/total')
    end
  end

  context 'when providing an invalid filter' do
    let(:filter) do
      [
        {
          "some": "bogus"
        }
      ]
    end

    it 'returns an error' do
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
        .at_path('errorIdentifier')
    end
  end
end
