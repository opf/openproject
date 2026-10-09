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

RSpec.describe "Mentioning members in a forum message", :js do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:author) do
    create(:user, firstname: "Anna", lastname: "Author",
                  member_with_permissions: { project => %i[view_messages add_messages], other_project => %i[view_project] })
  end
  shared_let(:member) do
    create(:user, firstname: "Bob", lastname: "Member", member_with_permissions: { project => %i[view_messages] })
  end
  shared_let(:outsider) do
    create(:user, firstname: "Bob", lastname: "Outsider", member_with_permissions: { other_project => %i[view_project] })
  end
  shared_let(:topic) { create(:message, forum:, subject: "Release planning") }

  let(:show_page) { Pages::Messages::Show.new(topic) }
  let(:editor) { Components::WysiwygEditor.new("#reply") }

  before { login_as(author) }

  it "suggests the topic's members only and mentions the picked one", :aggregate_failures do
    show_page.visit!

    editor.click_and_type_slowly("@Bob")

    # The outsider shares a project with the author, so only the topic's membership keeps them out.
    expect(page).to have_css(".mention-list-item", text: "Bob Member")
    expect(page).to have_no_css(".mention-list-item", text: "Bob Outsider")

    editor.click_autocomplete("Bob Member")
    click_button "Reply"

    expect(page).to have_link("Bob Member")
    expect(Message.last.content).to include(%(data-id="#{member.id}"))
  end
end
