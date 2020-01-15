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

describe ::API::Decorators::AggregationGroup do
  let(:query) do
    query = FactoryBot.build_stubbed(:query)
    query.group_by = :assigned_to

    query
  end
  let(:group_key) { OpenStruct.new name: 'ABC' }
  let(:count) { 5 }
  let(:current_user) { FactoryBot.build_stubbed(:user) }

  subject { described_class.new(group_key, count, query: query, current_user: current_user).to_json }

  context 'with an empty array key' do
    let(:group_key) { [] }

    it 'has an empty value' do
      is_expected
        .to be_json_eql(nil.to_json)
        .at_path('value')
    end
  end
end
