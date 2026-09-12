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

RSpec.describe Activities::MessageActivityProvider do
  let(:event_scope) { "messages" }
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:forum) { create(:forum, project:) }

  describe ".find_events" do
    let(:events) do
      described_class
        .find_events(event_scope, user, Time.zone.yesterday.to_datetime, Time.zone.tomorrow.to_datetime, {})
    end

    context "for a topic" do
      let!(:topic) { create(:message, forum:, author: user) }

      it "links to the forum topic" do
        expect(events.first.event_path)
          .to eq("/projects/#{project.identifier}/forums/#{forum.id}/topics/#{topic.id}")
      end
    end

    context "for a reply" do
      let(:topic) { create(:message, forum:, author: user) }
      let!(:reply) { create(:message, forum:, parent: topic, author: user) }

      it "links to the replied message in its forum topic" do
        expect(events.first.event_path)
          .to eq("/projects/#{project.identifier}/forums/#{forum.id}/topics/#{topic.id}?r=#{reply.id}#message-#{reply.id}")
      end
    end
  end
end
