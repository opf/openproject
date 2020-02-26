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

describe ::Query::Results, 'Grouping and sorting for version', type: :model, with_mail: false do
  let(:query_results) do
    ::Query::Results.new query
  end
  let(:project_1) { FactoryBot.create :project }
  let(:role_dev) do
    FactoryBot.create(:role,
                      permissions: [:view_work_packages])
  end
  let(:user_1) do
    FactoryBot.create(:user,
                      firstname: 'user',
                      lastname: '1',
                      member_in_project: project_1,
                      member_through_role: [role_dev])
  end

  let(:old_version) do
    FactoryBot.create(:version, name: 'Old version',
                      project: project_1,
                      start_date: '2019-02-02',
                      effective_date: '2019-02-03')
  end

  let(:new_version) do
    FactoryBot.create(:version,
                      name: 'New version',
                      project: project_1,
                      start_date: '2020-02-02',
                      effective_date: '2020-02-03')
  end

  let(:no_date_version) do
    FactoryBot.create(:version,
                      name: 'No date',
                      project: project_1,
                      start_date: nil,
                      effective_date: nil)
  end


  let!(:oldest_version_wp) do
    FactoryBot.create(:work_package,
                      fixed_version: old_version,
                      project: project_1)
  end
  let!(:newest_version_wp) do
    FactoryBot.create(:work_package,
                      fixed_version: new_version,
                      project: project_1)
  end
  let!(:no_date_version_wp) do
    FactoryBot.create(:work_package,
                      fixed_version: no_date_version,
                      project: project_1)
  end

  before do
    login_as(user_1)
  end

  describe 'grouping by fixed_version' do
    let(:query) do
      FactoryBot.build :query,
                       show_hierarchies: false,
                       group_by: 'fixed_version',
                       project: project_1
    end


    it 'returns the correct sorted grouped result' do
      expect(query_results.work_package_count_by_group)
        .to eql(old_version => 1, new_version => 1, no_date_version => 1)

      expect(query_results.sorted_work_packages)
        .to match [newest_version_wp, oldest_version_wp, no_date_version_wp]
    end
  end

  describe 'sorting ASC by version' do
    let(:query) do
      query = FactoryBot.build(:query, user: user_1, project: project_1)

      query.filters.clear
      query.sort_criteria = [['fixed_version', 'asc']]
      query
    end

    it 'returns the correct sorted result' do
      expect(query_results.sorted_work_packages.pluck(:id))
        .to match [oldest_version_wp, newest_version_wp, no_date_version_wp].map(&:id)
    end
  end

  describe 'sorting ASC by version' do
    let(:query) do
      query = FactoryBot.build(:query, user: user_1, project: project_1)

      query.filters.clear
      query.sort_criteria = [['fixed_version', 'desc']]
      query
    end

    it 'returns the correct sorted result' do
      expect(query_results.sorted_work_packages.pluck(:id))
        .to match [newest_version_wp, oldest_version_wp, no_date_version_wp].map(&:id)
    end
  end
end
