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

describe ::Query::Results, 'Sorting of custom field floats', type: :model, with_mail: false do
  let(:query_results) do
    ::Query::Results.new query
  end
  let(:user) do
    FactoryBot.create(:user,
                      firstname: 'user',
                      lastname: '1',
                      member_in_project: project,
                      member_with_permissions: [:view_work_packages])
  end

  let(:type) { FactoryBot.create(:type_standard, custom_fields: [custom_field]) }
  let(:project) do
    FactoryBot.create :project,
                      types: [type],
                      work_package_custom_fields: [custom_field]
  end
  let(:work_package_with_float) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: {custom_field.id => "6.25"}
  end

  let(:work_package_without_float) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project
  end

  let(:custom_field) do
    FactoryBot.create(:float_wp_custom_field, name: 'MyFloat')
  end

  let(:query) do
    FactoryBot.build(:query,
                     user: user,
                     show_hierarchies: false,
                     project: project).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  before do
    login_as(user)
    work_package_with_float
    work_package_without_float
  end

  describe 'sorting ASC by float cf' do
    let(:sort_criteria) { [["cf_#{custom_field.id}", 'asc']] }

    it 'returns the correctly sorted result' do
      expect(query_results.sorted_work_packages.pluck(:id))
        .to match [work_package_without_float, work_package_with_float].map(&:id)
    end
  end

  describe 'sorting DESC by float cf' do
    let(:sort_criteria) { [["cf_#{custom_field.id}", 'desc']] }

    it 'returns the correctly sorted result' do
      expect(query_results.sorted_work_packages.pluck(:id))
        .to match [work_package_with_float, work_package_without_float].map(&:id)
    end
  end
end
