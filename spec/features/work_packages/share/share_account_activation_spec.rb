# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Work package sharing invited users",
               :js, :with_cuprite,
               with_ee: %i[work_package_sharing] do
  shared_let(:edit_work_package_role) { create(:edit_work_package_role) }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:view_work_package_role) { create(:view_work_package_role) }
  shared_let(:editor) { create(:admin, firstname: "Mr.", lastname: "Sharer") }

  shared_let(:sharer_role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_shared_work_packages
                           share_work_packages))
  end

  shared_let(:project) do
    create(:project,
           members: { editor => [sharer_role] })
  end

  shared_let(:work_package) do
    create(:work_package, project:)
  end
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Sharing::WorkPackages::ShareModal.new(work_package) }

  it "allows to invite and activate the account" do
    login_with(editor.login, "adminADMIN!")
    expect(page).to have_current_path "/my/page"

    work_package_page.visit!
    work_package_page.click_share_button

    share_modal.expect_open
    # Invite a user that does not exist yet
    share_modal.invite_user("foobar@example.com", "View")
    # New user is shown in the list of shares
    share_modal.expect_shared_count_of(1)

    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.size).to eq(1)

    link = ActionMailer::Base.deliveries.first.text_part.body.encoded.scan(/http:\/\/.+$/).first.chomp
    token = Token::Invitation.last
    user = token.user
    expect(token).to be_present
    expect(user).to be_invited
    expect(user.mail).to eq "foobar@example.com"
    expect(link).to include token.value

    # Can log in and register the first time
    visit signout_path
    visit link

    expect(page).to have_text "Create a new account"
    password = SecureRandom.hex(16)

    fill_in "Password", with: password
    fill_in "Confirmation", with: password

    click_button "Create"

    expect(page).to have_text "Welcome, your account has been activated. You are logged in now."
    expect(page).to have_current_path project_work_package_path(project, work_package.id, "activity")

    expect(page).to have_text work_package.subject
    expect(user.reload).to be_active

    # Can log in with the link the second time
    visit signout_path
    visit link

    expect(page).to have_text "Sign in"
    login_with "foobar@example.com", password, visit_signin_path: false

    expect(page).to have_current_path project_work_package_path(project, work_package.id, "activity")
    expect(page).to have_text work_package.subject
  end
end
