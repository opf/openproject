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

describe ::API::V3::WorkPackages::WorkPackageSumsRepresenter do
  let(:sums) { double 'sums', story_points: 5, remaining_hours: 10 }
  let(:schema) { double 'schema', available_custom_fields: [] }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) {
    described_class.create_class(schema, user).new(sums)
  }
  let(:summable_columns) { [] }

  before do
    allow(Setting)
      .to receive(:work_package_list_summable_columns)
      .and_return(summable_columns)
  end

  subject { representer.to_json }

  context 'remainingTime' do
    context 'with it being configured to be summable' do
      let(:summable_columns) { ['remaining_hours'] }

      it 'is represented' do
        expected = 'PT10H'
        expect(subject).to be_json_eql(expected.to_json).at_path('remainingTime')
      end
    end

    context 'without it being configured to be summable' do
      it 'is not represented when the summable setting does not list it' do
        expect(subject).to_not have_json_path('remainingTime')
      end
    end
  end

  context 'storyPoints' do
    context 'with it being configured to be summable' do
      let(:summable_columns) { ['story_points'] }

      it 'is represented' do
        expect(subject).to be_json_eql(sums.story_points.to_json).at_path('storyPoints')
      end
    end

    context 'without it being configured to be summable' do
      it 'is not represented when the summable setting does not list it' do
        expect(subject).to_not have_json_path('storyPoints')
      end
    end
  end
end
