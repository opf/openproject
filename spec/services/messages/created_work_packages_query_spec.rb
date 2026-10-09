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

RSpec.describe Messages::CreatedWorkPackagesQuery do
  shared_let(:project) { create(:project) }
  shared_let(:hidden_project) { create(:project) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:reply) { create(:message, forum:, parent: topic) }
  shared_let(:other_topic) { create(:message, forum:) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_messages view_work_packages] }) }

  def created_from(message, project: self.project)
    create(:work_package, project:).tap { MessageWorkPackage.create!(message:, work_package: it) }
  end

  describe ".for_messages" do
    it "groups the work packages created from each message", :aggregate_failures do
      first = created_from(topic)
      second = created_from(topic)
      from_reply = created_from(reply)

      result = described_class.for_messages([topic, reply], user:)

      expect(result[topic.id]).to eq([first, second])
      expect(result[reply.id]).to eq([from_reply])
    end

    it "skips work packages the user cannot see" do
      created_from(topic, project: hidden_project)

      expect(described_class.for_messages([topic], user:)).to eq({})
    end

    it "answers an empty hash for no messages" do
      expect(described_class.for_messages([], user:)).to eq({})
    end
  end

  describe ".for_topic" do
    it "collects the work packages created from the topic and its replies, in creation order" do
      from_topic = created_from(topic)
      from_reply = created_from(reply)
      created_from(other_topic)

      expect(described_class.for_topic(topic, user:)).to eq([from_topic, from_reply])
    end

    it "skips work packages the user cannot see" do
      created_from(reply, project: hidden_project)

      expect(described_class.for_topic(topic, user:)).to be_empty
    end
  end
end
