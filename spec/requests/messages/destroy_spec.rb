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

RSpec.describe "Messages destroy redirect",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[forums]) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:message) { create(:message, forum:) }

  context "when an admin deletes a message" do
    current_user { create(:admin) }

    let(:request) { delete "/projects/#{project.id}/forums/#{forum.id}/topics/#{message.id}" }

    subject do
      request
      response
    end

    it "responds with 303 See Other and redirects to the forum" do
      expect(subject).to have_http_status(:see_other)
      expect(response).to redirect_to(project_forum_path(project, forum))

      expect { Message.find(message.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Forum.find(forum.id) }.not_to raise_error
    end
  end

  context "when deleting a reply message" do
    shared_let(:topic) { create(:message, forum:) }
    shared_let(:reply) { create(:message, forum:, parent: topic) }

    current_user { create(:admin) }

    let(:request) { delete "/projects/#{project.id}/forums/#{forum.id}/topics/#{reply.id}" }

    subject do
      request
      response
    end

    it "responds with 303 See Other and redirects to the topic" do
      expect(subject).to have_http_status(:see_other)
      expect(response).to redirect_to(project_forum_topic_path(project, forum, topic, r: reply))

      expect { Message.find(reply.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Message.find(topic.id) }.not_to raise_error
    end
  end
end
