#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

describe 'index placeholder users', type: :feature do
  let!(:current_user) { FactoryBot.create :admin }
  let!(:anonymous) { FactoryBot.create :anonymous }
  let!(:placeholder_user_1) do
    FactoryBot.create(:placeholder_user,
                      name: 'One',
                      created_at: 3.minute.ago)
  end
  let!(:placeholder_user_2) do
    FactoryBot.create(:placeholder_user,
                      name: 'Two',
                      created_at: 2.minute.ago)
  end
  let!(:placeholder_user_3) do
    FactoryBot.create(:placeholder_user,
                      name: 'Three',
                      created_at: 1.minute.ago)
  end
  let(:index_page) { Pages::Admin::PlaceholderUsers::Index.new }

  shared_examples 'placeholders index flow' do
    it 'shows the placeholder users and allows filtering and ordering' do
      index_page.visit!

      index_page.expect_not_listed(anonymous, current_user)

      # Order is by id, asc
      # so first ones created are on top.
      index_page.expect_listed(placeholder_user_1, placeholder_user_2, placeholder_user_3)

      index_page.order_by('Created on')
      index_page.expect_listed(placeholder_user_3, placeholder_user_2, placeholder_user_1)

      index_page.order_by('Created on')
      index_page.expect_listed(placeholder_user_1, placeholder_user_2, placeholder_user_3)

      index_page.filter_by_name(placeholder_user_3.name)
      index_page.expect_listed(placeholder_user_3)
      index_page.expect_not_listed(placeholder_user_1, placeholder_user_2)
    end
  end

  context 'as admin' do
    current_user { FactoryBot.create :admin }

    it_behaves_like 'placeholders index flow'
  end

  context 'as user with global permission' do
    current_user { FactoryBot.create :user, global_permission: %i[manage_placeholder_user] }

    it_behaves_like 'placeholders index flow'
  end

  context 'as user without global permission' do
    current_user { FactoryBot.create :user }

    it 'returns an error' do
      index_page.visit!
      expect(page).to have_text 'You are not authorized to access this page.'
    end
  end
end
