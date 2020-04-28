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

describe ::Query::Results, 'Subject filter integration', type: :model, with_mail: false do
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

  let!(:contains_wp) do
    FactoryBot.create(:work_package,
                      subject: 'The quick brown fox jumped',
                      project: project_1)
  end
  let!(:contains_reversed_wp) do
    FactoryBot.create(:work_package,
                      subject: 'The quick brown fox jumped',
                      project: project_1)
  end
  let!(:partially_contains_wp) do
    FactoryBot.create(:work_package,
                      subject: 'The quick brown goose jumped',
                      project: project_1)
  end
  let!(:not_contains_wp) do
    FactoryBot.create(:work_package,
                      subject: 'Something completely different',
                      project: project_1)
  end

  let(:query) do
    FactoryBot.build(:query,
                     user: user_1,
                     show_hierarchies: false,
                     project: project_1).tap do |q|
      q.filters.clear
    end
  end

  before do
    query.add_filter('subject', operator, values)

    login_as(user_1)
  end

  describe 'searching for contains' do
    let(:operator) { '~' }
    let(:values) { ['quick fox'] }

    it 'returns the work packages containing the string regardless of order' do
      expect(query_results.work_packages)
        .to match_array [contains_wp, contains_reversed_wp]
    end
  end

  describe 'searching for not contains' do
    let(:operator) { '!~' }
    let(:values) { ['quick fox'] }

    it 'returns the work packages not containing the string regardless of order' do
      expect(query_results.work_packages)
        .to match_array [not_contains_wp, partially_contains_wp]
    end
  end
end
