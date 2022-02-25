#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'API v3 work packages resource with storage filters', type: :request, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:work_package_with_file_link) do
    create(:work_package, author: current_user, project: project)
  end

  let(:work_package_without_file_link) do
    create(:work_package, author: current_user, project: project)
  end

  let(:storage) do
    create(:storage, creator: current_user)
  end

  let(:project_storage) { create(:project_storage, project: project, storage: storage) }

  let(:file_link) do
    create(:file_link, creator: current_user, container: work_package_with_file_link, storage: storage)
  end

  subject(:response) { last_response }

  before do
    project_storage
    login_as current_user
  end

  describe 'GET /api/v3/work_packages with filter on file link origin id' do
    let(:path) { api_v3_paths.path_for :work_packages, filters: filters }
    let(:origin_id_value) { file_link.origin_id.to_s }
    let(:filters) do
      [
        {
          file_link_origin_id: {
            operator: '=',
            values: [origin_id_value]
          }
        }
      ]
    end

    before do
      work_package_with_file_link
      work_package_without_file_link
      get path
    end

    it 'succeeds' do
      expect(subject.status).to be 200
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'WorkPackage', 'WorkPackageCollection' do
      let(:elements) { [work_package_with_file_link] }
    end

    context 'if the filter is set to an unknown file id from origin' do
      let(:origin_id_value) { "1337" }

      it 'succeeds' do
        expect(subject.status).to be 200
      end

      it_behaves_like 'API V3 collection response', 0, 0, 'WorkPackage', 'WorkPackageCollection' do
        let(:elements) { [] }
      end
    end

    context 'if the user has no permission to view file links' do
      let(:permissions) { %i(view_work_packages) }

      it 'succeeds' do
        expect(subject.status).to be 200
      end

      it_behaves_like 'API V3 collection response', 0, 0, 'WorkPackage', 'WorkPackageCollection' do
        let(:elements) { [] }
      end
    end
  end
end
