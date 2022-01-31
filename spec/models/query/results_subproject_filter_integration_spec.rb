#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

describe ::Query::Results, 'Subproject filter integration', type: :model, with_mail: false do
  let(:query) do
    build(:query,
                     user: user,
                     project: parent_project).tap do |q|
      q.filters.clear
    end
  end
  let(:query_results) do
    ::Query::Results.new query
  end

  shared_let(:parent_project) { create :project }
  shared_let(:child_project) { create :project, parent: parent_project }

  shared_let(:user) do
    create(:user,
                      firstname: 'user',
                      lastname: '1',
                      member_in_projects: [parent_project, child_project],
                      member_with_permissions: [:view_work_packages])
  end

  shared_let(:parent_wp) { create :work_package, project: parent_project }
  shared_let(:child_wp) { create :work_package, project: child_project }

  before do
    login_as user
  end

  context 'when subprojects included', with_settings: { display_subprojects_work_packages: true } do
    it 'shows the sub work packages' do
      expect(query_results.work_packages).to match_array [parent_wp, child_wp]
    end
  end

  context 'when subprojects not included', with_settings: { display_subprojects_work_packages: false } do
    it 'does not show the sub work packages' do
      expect(query_results.work_packages).to match_array [parent_wp]
    end

    context 'when subproject filter added manually' do
      before do
        query.add_filter('subproject_id', '=', [child_project.id])
      end

      it 'shows the sub work packages' do
        expect(query_results.work_packages).to match_array [parent_wp, child_wp]
      end
    end

    context 'when only subproject filter added manually' do
      before do
        query.add_filter('only_subproject_id', '=', [child_project.id])
      end

      it 'shows only the sub work packages' do
        expect(query_results.work_packages).to match_array [child_wp]
      end
    end
  end
end
