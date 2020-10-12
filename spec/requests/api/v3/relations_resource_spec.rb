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

describe 'API v3 Relation resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project_with_types) }
  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:permissions) { [] }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: project.types.first)
  end
  let(:visible_work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: project.types.first)
  end
  let(:invisible_work_package) do
    # will be inside another project
    FactoryBot.create(:work_package)
  end
  let(:visible_relation) do
    FactoryBot.create(:relation,
                      from: work_package,
                      to: visible_work_package)
  end
  let(:invisible_relation) do
    FactoryBot.create(:relation,
                      from: work_package,
                      to: invisible_work_package)
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  subject(:response) { last_response }

  describe '#get' do
    let(:path) { api_v3_paths.work_package_relations(work_package.id) }

    context 'when having the view_work_packages permission' do
      let(:permissions) { [:view_work_packages] }

      before do
        visible_relation
        invisible_relation

        get path
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Relation'
    end

    context 'when not having view_work_packages' do
      let(:permissions) { [] }

      before do
        get path
      end

      it_behaves_like 'not found'
    end
  end
end
