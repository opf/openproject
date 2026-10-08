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

RSpec.describe "Creating a work package from a forum message", :skip_csrf, type: :rails_request do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:topic) { create(:message, forum:, subject: "Release planning", content: "Opening post") }
  shared_let(:reply) { create(:message, forum:, parent: topic, content: "We should freeze on Friday") }
  shared_let(:member) do
    create(:user, member_with_permissions: { project => %i[view_messages view_work_packages add_work_packages] })
  end

  current_user { member }

  let(:dialog) { Capybara.string(response.body[%r{<template>(.*)</template>}m, 1].to_s) }

  it "opens the dialog with the topic's subject and the reply's content", :aggregate_failures do
    get new_project_forum_topic_work_package_path(project, forum, reply), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(dialog).to have_field("Subject", with: "Release planning")
    expect(dialog).to have_field("work_package[description]", with: "We should freeze on Friday", visible: :all)
    expect(dialog).to have_css("form[action='#{project_forum_topic_work_package_path(project, forum, reply)}']")
  end

  it "keeps the user's subject and description when the type changes", :aggregate_failures do
    post refresh_form_project_forum_topic_work_package_path(project, forum, reply),
         params: { work_package: { subject: "Freeze", description: "Edited", type_id: type.id } },
         as: :turbo_stream

    expect(dialog).to have_field("Subject", with: "Freeze")
    expect(dialog).to have_field("work_package[description]", with: "Edited", visible: :all)
  end

  it "creates the work package and returns to the message with a link to it", :aggregate_failures do
    post project_forum_topic_work_package_path(project, forum, reply),
         params: { work_package: { subject: "Freeze on Friday", description: "As discussed", type_id: type.id } }

    work_package = WorkPackage.last
    expect(work_package).to have_attributes(subject: "Freeze on Friday", project:)
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to("#{project_forum_topic_path(project, forum, topic)}?r=#{reply.id}#message-#{reply.id}")

    follow_redirect!

    expect(Capybara.string(response.body)).to have_text("Successful creation.")
      .and have_link("View #{work_package.formatted_id}", href: work_package_path(work_package))
  end

  it "re-renders the form with its errors", :aggregate_failures do
    post project_forum_topic_work_package_path(project, forum, reply),
         params: { work_package: { subject: "", type_id: type.id } },
         as: :turbo_stream

    expect(response).to have_http_status(:bad_request)
    expect(dialog).to have_text("Subject can't be blank")
    expect(WorkPackage.count).to eq(0)
  end

  context "without add_work_packages" do
    current_user { create(:user, member_with_permissions: { project => %i[view_messages view_work_packages] }) }

    it "forbids opening the dialog" do
      get new_project_forum_topic_work_package_path(project, forum, reply), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the project no longer uses forums" do
    before { project.update!(enabled_module_names: project.enabled_module_names - %w[forums]) }

    it "hides the message on every endpoint", :aggregate_failures do
      get new_project_forum_topic_work_package_path(project, forum, reply), as: :turbo_stream
      expect(response).to have_http_status(:not_found)

      post refresh_form_project_forum_topic_work_package_path(project, forum, reply),
           params: { work_package: { type_id: type.id } }, as: :turbo_stream
      expect(response).to have_http_status(:not_found)

      post project_forum_topic_work_package_path(project, forum, reply),
           params: { work_package: { subject: "X", type_id: type.id } }
      expect(response).to have_http_status(:not_found)
      expect(WorkPackage.count).to eq(0)
    end
  end
end
