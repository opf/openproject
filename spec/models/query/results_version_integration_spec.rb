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
  let(:user_1) do
    FactoryBot.create(:user,
                      firstname: 'user',
                      lastname: '1',
                      member_in_project: project_1,
                      member_with_permissions: [:view_work_packages])
  end

  let(:old_version) do
    FactoryBot.create(:version,
                      name: '1. Old version',
                      project: project_1,
                      start_date: '2019-02-02',
                      effective_date: '2019-02-03')
  end

  let(:new_version) do
    FactoryBot.create(:version,
                      name: '1.2 New version',
                      project: project_1,
                      start_date: '2020-02-02',
                      effective_date: '2020-02-03')
  end

  let(:no_date_version) do
    FactoryBot.create(:version,
                      name: '1.1 No date version',
                      project: project_1,
                      start_date: nil,
                      effective_date: nil)
  end

  let!(:no_version_wp) do
    FactoryBot.create(:work_package,
                      subject: 'No version wp',
                      project: project_1)
  end
  let!(:newest_version_wp) do
    FactoryBot.create(:work_package,
                      subject: 'Newest version wp',
                      version: new_version,
                      project: project_1)
  end
  let!(:oldest_version_wp) do
    FactoryBot.create(:work_package,
                      subject: 'Oldest version wp',
                      version: old_version,
                      project: project_1)
  end
  let!(:no_date_version_wp) do
    FactoryBot.create(:work_package,
                      subject: 'No date version wp',
                      version: no_date_version,
                      project: project_1)
  end

  let(:group_by) { nil }
  let(:sort_criteria) { [['version', 'asc']] }

  let(:query) do
    FactoryBot.build(:query,
                     user: user_1,
                     group_by: group_by,
                     show_hierarchies: false,
                     project: project_1).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end
  let(:work_packages_asc) { [oldest_version_wp, no_date_version_wp, newest_version_wp, no_version_wp] }

  before do
    login_as(user_1)
  end

  describe 'grouping by version' do
    let(:group_by) { 'version' }

    it 'returns the correctly sorted grouped result' do
      # Keys are also sorted by the version
      expect(query_results.work_package_count_by_group.keys)
        .to eql work_packages_asc.map(&:version)

      expect(query_results.work_package_count_by_group)
        .to eql(old_version => 1, no_date_version => 1, new_version => 1, nil => 1)

      expect(query_results.sorted_work_packages.pluck(:id))
        .to match work_packages_asc.map(&:id)
    end
  end

  describe 'sorting ASC by version' do
    let(:sort_criteria) { [['version', 'asc']] }

    it 'returns the correctly sorted result' do
      expect(query_results.sorted_work_packages.pluck(:id))
        .to match work_packages_asc.map(&:id)
    end
  end

  describe 'sorting DESC by version' do
    let(:sort_criteria) { [['version', 'desc']] }

    it 'returns the correctly sorted result' do
      # null values are still sorted last
      work_packages_order = [newest_version_wp, no_date_version_wp, oldest_version_wp, no_version_wp]

      expect(query_results.sorted_work_packages.pluck(:id))
        .to match work_packages_order.map(&:id)
    end
  end
end
