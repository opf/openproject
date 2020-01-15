#-- encoding: UTF-8

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

describe Queries::TimeEntries::Filters::UserFilter, type: :model do
  let(:user1) { FactoryBot.build_stubbed(:user) }
  let(:user2) { FactoryBot.build_stubbed(:user) }

  before do
    allow(Principal)
      .to receive_message_chain(:in_visible_project, :pluck)
      .with(:id)
      .and_return([user1.id, user2.id])
  end

  it_behaves_like 'basic query filter' do
    let(:class_key) { :user_id }
    let(:type) { :list_optional }
    let(:name) { TimeEntry.human_attribute_name(:user) }

    describe '#allowed_values' do
      it 'is a list of the possible values' do
        expected = [[user1.id, user1.id.to_s], [user2.id, user2.id.to_s]]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end

  it_behaves_like 'list_optional query filter' do
    let(:attribute) { :user_id }
    let(:model) { TimeEntry }
    let(:instance_key) { :user_id }
    let(:valid_values) { [user1.id.to_s] }
  end
end
