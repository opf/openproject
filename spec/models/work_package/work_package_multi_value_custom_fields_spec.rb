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

describe WorkPackage, type: :model do
  let(:type) { FactoryBot.create :type }
  let(:project) { FactoryBot.create :project, types: [type] }

  let(:custom_field) do
    FactoryBot.create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  let(:custom_values) do
    ["ham", "onions", "pineapple"].map do |str|
      custom_field.custom_options.find { |co| co.value == str }.try(:id)
    end
  end

  let(:work_package) do
    wp = FactoryBot.create :work_package, project: project, type: type
    wp.reload
    wp.custom_field_values = {
      custom_field.id => custom_values
    }
    wp.save
    wp
  end

  let(:values) { work_package.custom_value_for(custom_field) }
  let(:typed_values) { work_package.typed_custom_value_for(custom_field.id) }

  it 'returns the properly typed values' do
    expect(values.map { |cv| cv.value.to_i }).to eq(custom_values)
    expect(typed_values).to eq(%w(ham onions pineapple))
  end

  context 'when value not present' do
    let(:work_package) { FactoryBot.create :work_package, project: project, type: type }

    it 'returns nil properly' do
      expect(values).to eq(nil)
      expect(typed_values).to eq(nil)
    end
  end
end
