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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Forums user guide screenshots", :docs_screenshots, :js, with_ee: %i[team_planner_view work_package_sharing] do
  include_context "with user guide seed data", seeded_at: DocsScreenshots::FROZEN_AT

  let(:project) { Project.find_by!(identifier: "user-guide") }
  let(:customer_feedback) { project.forums.find_by!(name: "Customer feedback") }
  let(:usability_topics) { project.forums.find_by!(name: "Usability topics") }
  let(:topic) { customer_feedback.topics.find_by!(subject: "Agile Boards feedback") }
  let(:long_topic) { usability_topics.topics.find_by!(subject: "Dark mode: first impressions") }
  let(:unwatched_topic) { usability_topics.topics.find_by!(subject: "Your favorite keyboard shortcuts") }

  before { login_as User.find_by!(login: "mia.bayer") }

  def open_local_modifications
    page.document.synchronize(15) do
      click_on accessible_name: "Show local modifications"
      next if page.has_css?(".ck-dropdown__panel .ck-button", text: /words\)/, wait: 1)

      send_keys :escape
      raise Capybara::ExpectationNotMet, "CKEditor has not saved the draft locally yet"
    end
  end

  def open_post_actions(message)
    within_test_selector("forum-post-#{message.id}") { click_on accessible_name: "Message actions" }
  end

  it "captures the forums list and its management" do
    visit project_forums_path(project)
    docs_screenshot "forums/openproject_user_guide_forums_module"

    Pages::Forums::Index.new(project).within_forum(customer_feedback) { click_on accessible_name: "Forum actions" }
    docs_screenshot "forums/openproject_user_guide_forums_manage", crop: "#content"

    visit new_project_forum_path(project)
    fill_in "Name", with: "Feature requests"
    fill_in "Description", with: "Suggest new features here."
    docs_screenshot "forums/openproject_user_guide_forums_new_forum_create_form", crop: "#content"
  end

  it "captures a forum and sorting its topics" do
    visit project_forum_path(project, customer_feedback)
    docs_screenshot "forums/openproject_user_guide_forums_single_forum"

    within_test_selector("forum-topics-sort") { click_button "Recent activity" }
    docs_screenshot "forums/openproject_user_guide_forums_sort_topics", crop: "#content"
  end

  it "captures creating a topic" do
    visit new_project_forum_topic_path(project, customer_feedback)
    fill_in "Subject", with: "Gantt chart feedback"
    find(".ck-content").base.send_keys "What is your feedback on the Gantt charts in OpenProject?"
    docs_screenshot "forums/openproject_user_guide_forums_new_topic", crop: "#content"

    open_local_modifications
    docs_screenshot "forums/openproject_user_guide_forums_draft_saved_locally", crop: "#content"
    send_keys :escape

    click_button "Create"
    expect(page).to have_css(".PageHeader-title", text: "Gantt chart feedback")
    docs_screenshot "forums/openproject_user_guide_forums_new_topic_created"
  end

  it "captures a long topic with hidden replies" do
    visit project_forum_topic_path(project, usability_topics, long_topic)
    scroll_to find_test_selector("forum-thread-gap"), align: :center
    docs_screenshot "forums/openproject_user_guide_forums_load_previous_replies"
  end

  it "captures replying to a topic and the actions on a reply" do
    visit project_forum_topic_path(project, customer_feedback, topic)
    find("#reply .ck-content").base.send_keys "A board per team keeps ours readable."
    scroll_to find_by_id("reply"), align: :center
    docs_screenshot "forums/openproject_user_guide_forums_reply_form"

    click_button "Reply"
    expect(page).to have_css("[data-test-selector^='forum-post-']", text: "A board per team keeps ours readable.")
    docs_screenshot "forums/openproject_user_guide_forums_reply_saved"

    reply = topic.children.find_by!(content: "Thank you both, I passed it on to the product team.")
    visit project_forum_topic_path(project, customer_feedback, topic)
    scroll_to find_test_selector("forum-post-#{reply.id}"), align: :center
    open_post_actions(reply)
    docs_screenshot "forums/openproject_user_guide_forums_post_actions"
  end

  it "captures creating a work package from a reply" do
    reply = topic.children.find_by!(author: User.find_by!(login: "jonas.weber"))
    visit project_forum_topic_path(project, customer_feedback, topic)
    scroll_to find_test_selector("forum-post-#{reply.id}"), align: :center
    find_test_selector("forum-post-#{reply.id}").hover
    docs_screenshot "forums/openproject_user_guide_forums_add_work_package_button"

    # Rolled-back examples keep advancing the id sequence, which the work package number shows.
    WorkPackage.connection.set_pk_sequence!(WorkPackage.table_name, 41)
    find_test_selector("message-create-work-package-button-#{reply.id}").click
    within("#create-work-package-dialog") do
      expect(page).to have_field("Subject", with: "Agile Boards feedback")
      fill_in "Subject", with: "Add work packages to a Basic board list from the board"
    end
    docs_screenshot "forums/openproject_user_guide_forums_add_work_package_dialog"

    within("#create-work-package-dialog") { click_on "Create" }
    expect(page).to have_text("Successful creation.")
    docs_screenshot "forums/openproject_user_guide_forums_work_package_created"

    # Journaling stamps updated_at with the database clock, which the frozen time does not reach.
    WorkPackage.last.update_columns(updated_at: Time.current)
    visit project_work_package_path(project, WorkPackage.last.id, "activity")
    expect(page).to have_text("Created from forum message")
    docs_screenshot "forums/openproject_user_guide_forums_work_package_activity"
  end

  it "captures watching a forum and a topic" do
    visit project_forum_path(project, customer_feedback)
    docs_screenshot "forums/openproject_user_guide_forums_watch", crop: "#content"

    click_on "Watch"
    expect(page).to have_selector(:link_or_button, "Unwatch")
    docs_screenshot "forums/openproject_user_guide_forums_unwatch", crop: "#content"

    visit project_forum_topic_path(project, usability_topics, unwatched_topic)
    docs_screenshot "forums/openproject_user_guide_forums_watch_topic"
  end

  it "captures editing and deleting a topic" do
    visit project_forum_topic_path(project, customer_feedback, topic)
    open_post_actions(topic)
    docs_screenshot "forums/openproject_user_guide_forums_edit_topic"

    visit project_forum_topic_path(project, customer_feedback, topic)
    docs_screenshot "forums/openproject_user_guide_forums_delete_topic"
  end
end
