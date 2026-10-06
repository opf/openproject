# frozen_string_literal: true

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

RSpec.describe "Forums index", :js do
  shared_let(:project) { create(:project) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_messages manage_forums] }) }
  shared_let(:general) { create(:forum, project:, name: "General") }
  shared_let(:support) { create(:forum, project:, name: "Support") }
  shared_let(:offtopic) { create(:forum, project:, name: "Off-topic") }

  let(:forums_page) { Pages::Forums::Index.new(project) }

  # Reordering persists across examples, so each one starts from a known order.
  before do
    [general, support, offtopic].each_with_index { |forum, index| forum.update_column(:position, index + 1) }
    login_as(manager)
  end

  it "reorders forums through the action menu" do
    forums_page.visit!
    forums_page.expect_listed("General", "Support", "Off-topic")

    forums_page.click_forum_action(general, action: "Move to bottom")

    expect(page).to have_text("Successful update.")
    forums_page.expect_listed("Support", "Off-topic", "General")

    forums_page.click_forum_action(offtopic, action: "Move up")

    forums_page.expect_listed("Off-topic", "Support", "General")
  end
end
