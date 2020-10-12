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

describe 'API v3 Revisions by work package resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  let(:current_user) {
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  }
  let(:project) { FactoryBot.create(:project, public: false) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages, :view_changesets] }
  let(:repository) { FactoryBot.create(:repository_subversion, project: project) }
  let(:work_package) { FactoryBot.create(:work_package, author: current_user, project: project) }
  let(:revisions) { [] }

  subject(:response) { last_response }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    let(:get_path) { api_v3_paths.work_package_revisions work_package.id }

    before do
      revisions.each do |rev| rev.save! end
      get get_path
    end

    it 'should respond with 200' do
      expect(subject.status).to eq(200)
    end

    it_behaves_like 'API V3 collection response', 0, 0, 'Revision'


    context 'with existing revisions' do
      let(:revisions) {
        FactoryBot.build_list(:changeset,
                               5,
                               comments: "This commit references ##{work_package.id}",
                               repository: repository
        )
      }

      it_behaves_like 'API V3 collection response', 5, 5, 'Revision'

      context 'user unauthorized to view revisions' do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like 'API V3 collection response', 0, 0, 'Revision'
      end
    end

    context 'user unauthorized to view work package' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'should respond with 404' do
        expect(subject.status).to eq(404)
      end
    end

    describe 'revisions linked from another project' do
      let(:subproject) { FactoryBot.create(:project, parent: project) }
      let(:repository) { FactoryBot.create(:repository_subversion, project: subproject) }
      let!(:revisions) {
        FactoryBot.build_list(:changeset,
                               2,
                               comments: "This commit references ##{work_package.id}",
                               repository: repository
        )
      }

      context 'with permissions in subproject' do
        let(:current_user) {
          FactoryBot.create(:user,
                             member_in_projects: [project, subproject],
                             member_through_role: role)
        }

        it_behaves_like 'API V3 collection response', 2, 2, 'Revision'
      end

      context 'with no permission in subproject' do
        it_behaves_like 'API V3 collection response', 0, 0, 'Revision'
      end
    end
  end
end
