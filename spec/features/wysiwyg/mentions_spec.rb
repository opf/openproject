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

RSpec.describe "Wysiwyg work package mentions",
               :js do
  let!(:user) do
    create(:admin, firstname: "MeMyself", lastname: "AndI",
                   member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  let!(:user2) do
    create(:user, firstname: "Foo", lastname: "Bar",
                  member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  let!(:edit_work_package_role)    { create(:edit_work_package_role) }
  let!(:comment_work_package_role) { create(:comment_work_package_role) }
  let!(:view_work_package_role)    { create(:view_work_package_role) }

  let!(:work_package_editor) do
    create(:user, firstname: "Bertram", lastname: "Gilfoyle",
                  member_with_roles: { work_package => edit_work_package_role })
  end
  let!(:work_package_commenter) do
    create(:user, firstname: "Dinesh", lastname: "Chugtai",
                  member_with_roles: { work_package => comment_work_package_role })
  end
  let!(:work_package_viewer) do
    create(:user, firstname: "Richard", lastname: "Hendricks",
                  member_with_roles: { work_package => view_work_package_role })
  end

  let!(:group) { create(:group, firstname: "Foogroup", lastname: "Foogroup") }
  let!(:group_role) { create(:project_role) }
  let!(:group_member) do
    create(:member,
           principal: group,
           project:,
           roles: [group_role])
  end
  let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  let!(:status) { create(:default_status, name: "Some status") }
  let!(:work_package) do
    User.execute_as(user) do
      create(:work_package, subject: "Foobar", status:, author: user, project:)
    end
  end

  let!(:mentioned_work_package) do
    create(:work_package, subject: "Other work package", status:, author: user, project:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new work_package, project }
  let(:editor) { Components::WysiwygEditor.new }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  before do
    login_as(user)
    wp_page.visit!
    wait_for_reload
    expect_angular_frontend_initialized
    wp_page.wait_for_activity_tab
  end

  it "can autocomplete users, groups and emojis" do
    # Mentioning a user works
    activity_tab.type_comment("@Foo")
    expect(page).to have_css(".mention-list-item", text: user2.name)
    expect(page).to have_css(".mention-list-item", text: group.name)

    page.find(".mention-list-item", text: user2.name).click

    expect(page)
      .to have_css("a.mention", text: "@Foo Bar")

    activity_tab.submit_comment
    activity_tab.expect_journal_mention(text: "Foo Bar")

    # Mentioning myself works
    activity_tab.type_comment("@MeMyself")
    expect(page).to have_css(".mention-list-item", text: user.name)

    page.find(".mention-list-item", text: user.name).click

    expect(page)
      .to have_css("a.mention", text: "@MeMyself AndI")

    activity_tab.submit_comment
    activity_tab.expect_journal_mention(text: "MeMyself AndI")

    # Mentioning a work package editor or commenter works
    #
    # Editor
    #
    activity_tab.type_comment("@Bertram Gilfoyle")
    page.find(".mention-list-item", text: work_package_editor.name).click
    expect(page)
      .to have_css("a.mention", text: "@Bertram Gilfoyle")
    activity_tab.submit_comment
    activity_tab.expect_journal_mention(text: "Bertram Gilfoyle")

    #
    # Commenter
    #
    activity_tab.type_comment("@Dinesh Chugtai")
    page.find(".mention-list-item", text: work_package_commenter.name).click
    expect(page)
      .to have_css("a.mention", text: "@Dinesh Chugtai")
    activity_tab.submit_comment
    activity_tab.expect_journal_mention(text: "Dinesh Chugtai")

    # Work Package viewers aren't mentionable
    activity_tab.type_comment("@Richard Hendricks")
    page.driver.wait_for_reload
    expect(page)
        .to have_no_css(".mention-list-item", text: work_package_viewer.name)

    # clear input
    activity_tab.clear_comment(blur: true)
    activity_tab.dismiss_comment_editor_with_cancel_button

    # Mentioning a group works
    activity_tab.type_comment("@Foo")
    expect(page).to have_css(".mention-list-item", text: user2.name)
    expect(page).to have_css(".mention-list-item", text: group.name)

    page.find(".mention-list-item", text: group.name).click

    expect(page)
      .to have_css("a.mention", text: "@Foogroup")

    activity_tab.submit_comment
    activity_tab.expect_journal_mention(text: "Foogroup")

    # The mention is still displayed as such when reentering the comment field
    activity_tab.type_comment_in_edit(work_package.journals.last, " @Foo Bar")
    expect(page).to have_css(".mention-list-item", text: user2.name)

    page.find(".mention-list-item", text: user2.name).click

    expect(page)
      .to have_css("a.mention", text: "@Foogroup")
    expect(page)
      .to have_css("a.mention", text: "@Foo Bar")

    activity_tab.submit_comment

    # Mentioning an emoji works
    activity_tab.type_comment(":thumbs")
    expect(page).to have_css(".mention-list-item", text: "👍 thumbs_up")
    expect(page).to have_css(".mention-list-item", text: "👎 thumbs_down")

    page.find(".mention-list-item", text: "👍 thumbs_up").click

    expect(page).to have_css("span", text: "👍")
  end

  # Each consuming context defines `wp_display_id` — the value the user
  # types after the marker, which appears on the rendered widget as
  # `data-display-id` — and `wp_label`, the visible link label after the
  # macro pipeline renders the comment.
  shared_examples "work package mention with all triggers" do
    it "can autocomplete work packages with different triggers" do
      # Test # trigger
      activity_tab.type_comment("##{wp_display_id}")
      page.find(".mention-list-item", text: mentioned_work_package.subject, wait: 10).click
      expect(page).to have_css("a.mention", text: "##{wp_display_id}")
      activity_tab.submit_comment
      activity_tab.expect_journal_notes text: wp_label

      # Test ## trigger
      activity_tab.type_comment("###{wp_display_id}")
      page.find(".mention-list-item", text: mentioned_work_package.subject, wait: 10).click
      expect(page).to have_css(".op-macro-wp-quickinfo-widget")
      expect(page).to have_css(
        "opce-macro-wp-quickinfo" \
        "[data-id='#{mentioned_work_package.id}']" \
        "[data-display-id='#{wp_display_id}']" \
        "[data-detailed='false']"
      )
      activity_tab.submit_comment
      activity_tab.expect_journal_notes text: "NONE #{wp_label}: #{mentioned_work_package.subject}"

      # Test ### trigger
      activity_tab.type_comment("####{wp_display_id}")
      page.find(".mention-list-item", text: mentioned_work_package.subject, wait: 10).click
      expect(page).to have_css(".op-macro-wp-quickinfo-widget")
      expect(page).to have_css(
        "opce-macro-wp-quickinfo" \
        "[data-id='#{mentioned_work_package.id}']" \
        "[data-display-id='#{wp_display_id}']" \
        "[data-detailed='true']"
      )
      activity_tab.submit_comment

      activity_tab.expect_journal_notes text: "Some statusNONE #{wp_label}: #{mentioned_work_package.subject}"
    end
  end

  context "in classic mode",
          with_settings: { work_packages_identifier: "classic" } do
    let(:wp_display_id) { mentioned_work_package.id }
    let(:wp_label) { "##{mentioned_work_package.id}" }

    include_examples "work package mention with all triggers"
  end

  context "in semantic mode",
          with_settings: { work_packages_identifier: "semantic" } do
    let!(:project) do
      create(:project, :semantic, enabled_module_names: %w[work_package_tracking])
    end
    let!(:mentioned_work_package) do
      create(:work_package, subject: "Other work package", status:, author: user, project:).tap do |wp|
        wp.allocate_and_register_semantic_id
        wp.reload
      end
    end
    let(:wp_display_id) { mentioned_work_package.identifier }
    let(:wp_label) { mentioned_work_package.identifier }

    include_examples "work package mention with all triggers"
  end
end
