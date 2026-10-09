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

RSpec.describe MessagesHelper do
  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:reply) { create(:message, forum:, parent: topic) }

  # Every reply card on a thread page builds this link, so it must not load the reply's topic.
  let(:loaded_reply) { Message.includes(forum: :project).find(reply.id) }
  let(:topic_path) { "/projects/#{forum.project.identifier}/forums/#{forum.id}/topics/#{topic.id}" }

  describe "#message_anchor_path" do
    it "links a reply on its topic page without loading the topic", :aggregate_failures do
      expect(helper.message_anchor_path(loaded_reply)).to eq("#{topic_path}?r=#{reply.id}#message-#{reply.id}")
      expect(loaded_reply.association(:parent)).not_to be_loaded
    end
  end

  describe "#message_url" do
    it "links a reply on its topic page without loading the topic", :aggregate_failures do
      expect(helper.message_url(loaded_reply)).to end_with("#{topic_path}?r=#{reply.id}#message-#{reply.id}")
      expect(loaded_reply.association(:parent)).not_to be_loaded
    end
  end
end
