#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "News creation and commenting", :js, :with_cuprite do
  let(:project) { create(:project) }
  let!(:other_user) do
    create(:user,
           member_with_permissions: { project => %i[] },
           notification_settings: [
             build(:notification_setting, news_added: true, news_commented: true)
           ])
  end

  current_user do
    create(:user,
           member_with_permissions: { project => %i[manage_news comment_news] })
  end

  it "allows creating new and commenting it all of which will result in notifications and mails" do
    visit project_news_index_path(project)

    within ".toolbar-items" do
      click_link "News"
    end

    # Create the news
    fill_in "Title", with: "My new news"
    fill_in "Summary", with: "The news summary"

    perform_enqueued_jobs do
      click_button "Create"
    end

    # The new news is visible on the index page
    expect(page)
      .to have_link("My new news")

    expect(page)
      .to have_content "The news summary"

    # Creating the news will have sent out mails
    expect(ActionMailer::Base.deliveries.size)
      .to eq 1

    expect(ActionMailer::Base.deliveries.last.to)
      .to contain_exactly(other_user.mail)

    expect(ActionMailer::Base.deliveries.last.subject)
      .to include "My new news"

    click_link "My new news"

    comment_editor = Components::WysiwygEditor.new
    comment_editor.set_markdown "A new **text**"

    perform_enqueued_jobs do
      click_button "Add comment"
    end

    # The new comment is visible on the show page
    expect(page)
      .to have_content "A new text"

    # Creating the news comment will have sent out mails
    expect(ActionMailer::Base.deliveries.size)
      .to eq 2

    expect(ActionMailer::Base.deliveries.last.to)
      .to contain_exactly(other_user.mail)

    expect(ActionMailer::Base.deliveries.last.subject)
      .to include "My new news"
  end
end
