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
         'with greater_or_equal_or_null and less_or_equal_or_null',
         type: :model do

  let(:cf_accessor) { "cf_#{custom_field.id}" }
  let(:query) { FactoryBot.build_stubbed(:query, project: project) }
  let(:instance) do
    described_class.create!(name: cf_accessor, operator: operator, values: values, context: query)
  end

  let(:project) do
    FactoryBot.create :project,
                      types: [type],
                      work_package_custom_fields: [custom_field]
  end
  let(:custom_field) do
    FactoryBot.create(:integer_issue_custom_field, name: 'NotRequiredInt')
  end
  let(:type) { FactoryBot.create(:type_standard, custom_fields: [custom_field]) }

  let!(:wp_5) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => 5 }
  end
  let!(:wp_8) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => 8 }
  end

  let!(:wp_nil) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: { custom_field.id => nil }
  end

  subject { WorkPackage.where(instance.where) }

  describe '>=? 2' do
    let(:operator) { '>=?' }
    let(:values) { 2 }

    it 'returns three matching work package' do
      is_expected
        .to match_array [wp_5, wp_8, wp_nil]
    end
  end

  describe '>=? 5' do
    let(:operator) { '>=?' }
    let(:values) { 5 }

    it 'returns three matching work packages' do
      is_expected
        .to match_array [wp_5, wp_8, wp_nil]
    end
  end

  describe '>=? 7' do
    let(:operator) { '>=?' }
    let(:values) { 7 }

    it 'returns two matching work packages' do
      is_expected
        .to match_array [wp_8, wp_nil]
    end
  end

  describe '>=? 9' do
    let(:operator) { '>=?' }
    let(:values) { 9 }

    it 'returns one matching work package' do
      is_expected
        .to match_array [wp_nil]
    end
  end

  describe '<=? 2' do
    let(:operator) { '<=?' }
    let(:values) { 2 }

    it 'returns one matching work package' do
      is_expected
        .to match_array [wp_nil]
    end
  end

  describe '<=? 5' do
    let(:operator) { '<=?' }
    let(:values) { 5 }

    it 'returns two matching work packages' do
      is_expected
        .to match_array [wp_5, wp_nil]
    end
  end

  describe '<=? 7' do
    let(:operator) { '<=?' }
    let(:values) { 7 }

    it 'returns two matching work packages' do
      is_expected
        .to match_array [wp_5, wp_nil]
    end
  end

  describe '<=? 9' do
    let(:operator) { '<=?' }
    let(:values) { 9 }

    it 'returns three matching work packages' do
      is_expected
        .to match_array [wp_5, wp_8, wp_nil]
    end
  end

end
