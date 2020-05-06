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

describe Queries::WorkPackages::Filter::CustomFieldFilter,
         'with contains filter (Regression test #28348)',
         type: :model do
  let(:cf_accessor) { "cf_#{custom_field.id}" }
  let(:query) { FactoryBot.build_stubbed(:query, project: project) }
  let(:instance) do
    described_class.create!(name: cf_accessor, operator: operator, values: %w(foo), context: query)
  end

  let(:project) do
    FactoryBot.create :project,
                      types: [type],
                      work_package_custom_fields: [custom_field]
  end
  let(:custom_field) do
    FactoryBot.create(:text_issue_custom_field, name: 'LongText')
  end
  let(:type) { FactoryBot.create(:type_standard, custom_fields: [custom_field]) }

  let!(:wp_contains) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => 'foo' }
  end
  let!(:wp_not_contains) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => 'bar' }
  end

  let!(:wp_empty) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => '' }
  end

  let!(:wp_nil) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => nil }
  end

  subject { WorkPackage.where(instance.where) }

  describe 'contains' do
    let(:operator) { '~' }

    it 'returns the one matching work package' do
      is_expected
        .to match_array [wp_contains]
    end
  end

  describe 'not contains' do
    let(:operator) { '!~' }

    it 'returns the three non-matching work package' do
      is_expected
        .to match_array [wp_not_contains, wp_empty, wp_nil]
    end
  end
end
