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

describe Queries::UpdateService do
  let(:query) { FactoryBot.create(:query, user: user) }
  let(:menu_item) do
    FactoryBot.create(:query_menu_item,
                      query: query)
  end
  let(:user) { FactoryBot.create(:admin) }
  let(:instance) { described_class.new(user: user) }

  describe "a query's menu item" do
    before do
      query
      menu_item
    end

    context 'successful saving' do
      before do
        query.name = 'blubs'
      end

      it 'is renamed along with the query' do
        instance.call(query)

        expect(menu_item.reload.title).to eql 'blubs'
      end

      it 'is successful' do
        expect(instance.call(query)).to be_success
      end
    end

    context 'unsuccessful saving of the menu item' do
      before do
        # violating the validations
        violating_menu_item = FactoryBot.build(:query_menu_item,
                                                name: menu_item.name,
                                                navigatable_id: menu_item.navigatable_id)

        violating_menu_item.save(validate: false)

        query.name = 'blubs'
      end

      it 'does not rename the menu item' do
        instance.call(query)

        expect(menu_item.reload.title).not_to eql 'blubs'
      end

      it 'is unsuccessful' do
        expect(instance.call(query)).not_to be_success
      end

      it 'explains the error' do
        expect(instance.call(query).errors['name']).to be_present
      end
    end

    context 'unsuccessful saving of the query' do
      before do
        query.name = 'blubs'

        # violating the validations
        query.group_by = 'some bogus'
      end

      it 'does not rename the menu item' do
        instance.call(query)

        expect(menu_item.reload.title).not_to eql 'blubs'
      end

      it 'is unsuccessful' do
        expect(instance.call(query)).not_to be_success
      end

      it 'explains the error' do
        expect(instance.call(query).errors['group_by']).to be_present
      end
    end
  end
end
