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

describe 'sticky messages', type: :feature do
  let(:forum) { FactoryBot.create(:forum) }

  let!(:message1) do
    FactoryBot.create :message, forum: forum, created_on: Time.now - 1.minute do |message|
      Message.where(id: message.id).update_all(updated_on: Time.now - 1.minute)
    end
  end
  let!(:message2) do
    FactoryBot.create :message, forum: forum, created_on: Time.now - 2.minute do |message|
      Message.where(id: message.id).update_all(updated_on: Time.now - 2.minute)
    end
  end
  let!(:message3) do
    FactoryBot.create :message, forum: forum, created_on: Time.now - 3.minute do |message|
      Message.where(id: message.id).update_all(updated_on: Time.now - 3.minute)
    end
  end

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: forum.project,
                      member_through_role: role
  end
  let(:role) { FactoryBot.create(:role, permissions: [:edit_messages]) }

  before do
    login_as user
    visit project_forum_path(forum.project, forum)
  end

  def expect_order_of_messages(*order)
    order.each_with_index do |message, index|
      expect(page).to have_selector("table tbody tr:nth-of-type(#{index + 1})", text: message.subject)
    end
  end

  scenario 'sticky messages are on top' do
    expect_order_of_messages(message1, message2, message3)

    click_link(message2.subject)

    click_link('Edit')

    check('message[sticky]')
    click_button('Save')

    visit project_forum_path(forum.project, forum)

    expect_order_of_messages(message2, message1, message3)
  end
end
