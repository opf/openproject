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

RSpec.describe "Messages update forum authorization",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[forums]) }
  shared_let(:source_forum) { create(:forum, project:) }
  shared_let(:destination_forum) { create(:forum, project:) }
  shared_let(:topic_author) do
    create(:user, member_with_permissions: { project => %i[view_messages add_messages edit_messages] })
  end
  shared_let(:topic) { create(:message, forum: source_forum, author: topic_author) }

  current_user do
    create(:user, member_with_permissions: { project => %i[view_messages add_messages edit_own_messages] })
  end

  let(:reply) do
    create(:message, forum: source_forum, parent: topic, author: current_user)
  end

  subject do
    put "/projects/#{project.id}/forums/#{source_forum.id}/topics/#{reply.id}",
        params: { message: { forum_id: destination_forum.id } }
    response
  end

  it "does not move the discussion thread to another forum" do
    subject

    expect(topic.reload.forum_id).to eq(source_forum.id)
    expect(reply.reload.forum_id).to eq(source_forum.id)
  end

  it "still allows editing own reply content" do
    put "/projects/#{project.id}/forums/#{source_forum.id}/topics/#{reply.id}",
        params: { message: { content: "updated content" } }

    expect(response).to have_http_status(:found)
    expect(reply.reload.content).to eq("updated content")
  end
end
