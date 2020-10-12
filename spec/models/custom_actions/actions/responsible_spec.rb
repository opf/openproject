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
require_relative '../shared_expectations'

describe CustomActions::Actions::Responsible, type: :model do
  let(:key) { :responsible }
  let(:type) { :associated_property }
  let(:allowed_values) do
    users = [FactoryBot.build_stubbed(:user),
             FactoryBot.build_stubbed(:user)]

    allow(User)
      .to receive_message_chain(:active_or_registered, :select, :order_by_name)
            .and_return(users)

    [{ value: nil, label: '-' },
     { value: users.first.id, label: users.first.name },
     { value: users.last.id, label: users.last.name }]
  end

  it_behaves_like 'base custom action'
  it_behaves_like 'associated custom action' do
    describe '#allowed_values' do
      context 'group assignment disabled', with_settings: { work_package_group_assignment?: false } do
        it 'is the list of all users' do
          allowed_values

          expect(instance.allowed_values)
            .to eql(allowed_values)
        end
      end

      context 'group assignment enabled', with_settings: { work_package_group_assignment?: true } do
        it 'is the list of all users' do
          allowed_values

          expect(instance.allowed_values)
            .to eql(allowed_values)
        end
      end
    end
  end
end
