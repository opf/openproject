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

describe 'messages', type: :feature, js: true do
  let(:forum) do
    FactoryBot.create(:forum)
  end

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: forum.project,
                      member_through_role: role,
                      notification_settings: [FactoryBot.build(:notification_setting, all: false)]
  end
  let(:other_user) do
    FactoryBot.create(:user,
                      member_in_project: forum.project,
                      member_through_role: role,
                      notification_settings: [FactoryBot.build(:notification_setting, all: false)]).tap do |u|
      forum.watcher_users << u
    end
  end
  let(:role) { FactoryBot.create(:role, permissions: [:add_messages]) }

  let(:index_page) { Pages::Messages::Index.new(forum.project) }

  before do
    other_user
    login_as user
  end

  it 'adding, checking replies, replying' do
    index_page.visit!
    click_link forum.name

    create_page = index_page.click_create_message

    SeleniumHubWaiter.wait
    create_page.set_subject 'The message is'
    create_page.click_save

    create_page.expect_notification(type: :error, message: 'Content can\'t be blank')
    SeleniumHubWaiter.wait
    create_page.add_text 'There is no message here'

    show_page = perform_enqueued_jobs do
      create_page.click_save
    end


    show_page.expect_current_path

    show_page.expect_subject('The message is')
    show_page.expect_content('There is no message here')

    index_page.visit!
    click_link forum.name
    index_page.expect_listed(subject: 'The message is',
                             replies: 0)

    # Register as a watcher to later on get mails
    click_link 'Watch'

    # Creating a message will have sent a mail to the other user who was already watching the forum
    expect(ActionMailer::Base.deliveries.size)
      .to be 1

    expect(ActionMailer::Base.deliveries.last.to)
      .to match_array [other_user.mail]

    expect(ActionMailer::Base.deliveries.last.subject)
      .to include 'The message is'

    # Replying as other user

    login_as other_user

    show_page.visit!
    show_page.expect_no_replies

    reply = perform_enqueued_jobs do
      show_page.reply 'But, but there should be one'
    end

    show_page.expect_current_path(reply)
    show_page.expect_num_replies(1)

    show_page.expect_reply(subject: 'RE: The message is',
                           content: 'But, but there should be one')

    index_page.visit!
    click_link forum.name

    index_page.expect_listed(subject: 'The message is',
                             replies: 1,
                             last_message: 'RE: The message is')

    # Creating a reply will have sent a mail to the first user who was watching the forum
    expect(ActionMailer::Base.deliveries.size)
      .to be 2

    expect(ActionMailer::Base.deliveries.last.to)
      .to match_array [user.mail]

    expect(ActionMailer::Base.deliveries.last.subject)
      .to include 'RE: The message is'

    # Quoting as first user again
    login_as user

    show_page.visit!
    quote = show_page.quote(quoted_message: reply,
                            subject: 'And now to something completely different',
                            content: "No, there really isn't\n\n")

    show_page.expect_current_path(quote)

    show_page.expect_num_replies(2)
    show_page.expect_reply(reply: quote,
                           subject: 'And now to something completely different',
                           content: 'No, there really isn\'t')

    expect(page).to have_selector('blockquote', text: 'But, but there should be one')

    index_page.visit!
    click_link forum.name
    index_page.expect_listed(subject: 'The message is',
                             replies: 2,
                             last_message: 'And now to something completely different')
  end
end
