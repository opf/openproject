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

RSpec.describe "Document mention notifications in the notification center", :js do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[documents work_package_tracking]) }
  shared_let(:mentioner) do
    create(:user,
           firstname: "Jean",
           lastname: "Cérien",
           member_with_permissions: { project => %i[view_documents manage_documents] })
  end
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { project => %i[view_documents view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:document) { create(:document, id: work_package.id, project:, title: "Take-off checklist (Robin DR-400)") }

  let!(:document_notification) do
    create(:notification,
           recipient:,
           resource: document,
           journal: nil,
           actor: mentioner,
           reason: :mentioned,
           read_ian: false)
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:side_menu) { Components::Submenu.new }

  current_user { recipient }

  def visit_center
    center.visit!
    wait_for_reload
  end

  it "shows the document row with only the title linked and leaves the row inert" do
    visit_center

    center.expect_bell_count 1
    center.expect_document_item document_notification
    center.within_item(document_notification) do
      expect(page).to have_text("by Jean Cérien", normalize_ws: true)
      expect(page).to have_css("a[href='#{project_path(project.id)}'][target='_blank']", exact_text: project.name)
      expect(page).to have_no_css("[role='button'].op-ian-item--row")
    end

    center.click_document_label document_notification
    wait_for_network_idle

    expect(page).to have_current_path(notifications_center_path, ignore_query: true)
    center.expect_item_not_read document_notification
    center.expect_bell_count 1
  end

  it "marks the document notification as read" do
    visit_center

    center.mark_notification_as_read document_notification

    center.expect_bell_count 0
    center.expect_no_item document_notification
    expect(document_notification.reload.read_ian).to be(true)
  end

  context "with a work package notification next to it" do
    let!(:work_package_notification) do
      create(:notification,
             recipient:,
             resource: work_package,
             reason: :assigned)
    end

    it "marks both as read with mark all as read" do
      visit_center
      center.expect_bell_count 2

      center.mark_all_read

      center.expect_bell_count 0
      center.expect_no_item document_notification, work_package_notification
    end

    it "does not select the document whose id equals the opened work package's id" do
      expect(document.id).to eq(work_package.id)

      visit_center
      center.expect_number_of_notifications 2
      center.click_item work_package_notification

      expect(page).to have_current_path(%r{/notifications/details/#{work_package.id}})
      center.expect_item_selected work_package_notification
      expect(page).to have_no_css(
        "[data-test-selector='op-ian-notification-item-#{document_notification.id}'][data-qa-ian-selected]"
      )
    end

    it "closes the split screen instead of opening the document's id when only the document is left" do
      visit_center
      center.expect_number_of_notifications 2
      center.click_item work_package_notification
      Pages::PrimerizedSplitWorkPackage.new(work_package).expect_open
      Components::WorkPackages::Activities.new(work_package).expect_wp_has_been_created_activity(work_package)

      center.mark_notification_as_read work_package_notification

      expect(page).to have_current_path(notifications_center_path, ignore_query: true)
      center.expect_number_of_notifications 1
      center.expect_document_item document_notification
    end
  end

  context "with document notifications from two projects" do
    shared_let(:other_project) { create(:project, enabled_module_names: %w[documents]) }
    shared_let(:other_document) { create(:document, project: other_project, title: "Pre-landing checklist") }

    let!(:other_document_notification) do
      create(:member,
             project: other_project,
             principal: recipient,
             roles: [create(:project_role, permissions: %i[view_documents])])
      create(:notification,
             recipient:,
             resource: other_document,
             journal: nil,
             actor: mentioner,
             reason: :mentioned,
             read_ian: false)
    end

    it "lists the document projects in the project filter" do
      visit_center
      center.expect_bell_count 2

      side_menu.expect_item_with_count other_project.name, 1
      side_menu.click_item other_project.name
      side_menu.finished_loading

      center.expect_document_item other_document_notification
      center.expect_no_item document_notification
    end
  end

  context "when the mention is created through the API" do
    let!(:document_notification) { nil }

    it "shows the notification in the recipient's notification center" do
      login_as mentioner
      api = Rack::Test::Session.new(Rails.application)
      api.post(api_v3_paths.notifications,
               {
                 reason: "mentioned",
                 _links: {
                   resource: { href: api_v3_paths.document(document.id) },
                   recipient: { href: api_v3_paths.user(recipient.id) }
                 }
               }.to_json,
               "CONTENT_TYPE" => "application/json")
      expect(api.last_response).to have_http_status(:created)

      login_as recipient
      visit_center

      center.expect_bell_count 1
      center.expect_document_item Notification.find_by!(resource: document, recipient:)
    end
  end
end
