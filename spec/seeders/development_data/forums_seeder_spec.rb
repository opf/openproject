# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe DevelopmentData::ForumsSeeder do
  subject(:seeder) { described_class.new }

  describe "#applicable?" do
    it "is not applicable without the dev-forums project" do
      expect(seeder).not_to be_applicable
    end

    context "with the dev-forums project" do
      let!(:project) { create(:project, identifier: "dev-forums") }

      it "is applicable while the project has no forums" do
        expect(seeder).to be_applicable
      end

      it "is not applicable once the project has forums" do
        create(:forum, project:)

        expect(seeder).not_to be_applicable
      end
    end
  end

  describe "#seed_data!" do
    shared_let(:project) { create(:project, identifier: "dev-forums", enabled_module_names: %w[work_package_tracking]) }
    shared_let(:authors) do
      [create(:admin, login: "admin"), *%w[reader member work_packager project_admin admin_de].map { create(:user, login: it) }]
    end

    let(:general) { project.forums.find_by!(name: "General") }

    before { seeder.seed_data! }

    it "turns the forums module on" do
      expect(project.reload.enabled_module_names).to include("forums")
    end

    it "seeds the forums in order, one of them empty", :aggregate_failures do
      expect(project.forums.order(:position).map(&:name)).to eq(%w[General Support Announcements])
      expect(project.forums.find_by!(name: "Announcements").topics).to be_empty
    end

    it "seeds sticky, locked, and sticky locked topics", :aggregate_failures do
      expect(general.topics.where(sticky: true, locked: false)).to exist
      expect(general.topics.where(sticky: false, locked: true)).to exist
      expect(general.topics.where(sticky: true, locked: true)).to exist
    end

    it "dates each topic's activity to its latest message, so the activity sorts mean something" do
      general.topics.each do |topic|
        latest = [topic, *topic.children].map(&:created_at).max

        expect(topic.updated_at).to be_within(1.second).of(latest), topic.subject
      end
    end

    it "dates each pinning to the topic's start" do
      general.topics.where(sticky: true).each do |topic|
        expect(topic.sticked_on).to be_within(1.second).of(topic.created_at), topic.subject
      end
    end

    it "starts the forum with a topic asking whether it works" do
      expect(general.topics.reorder(:created_at).first.subject).to eq("First message. Does it work?")
    end

    it "seeds topics without replies, with a few, and with enough to hide some" do
      expect(general.topics.map(&:replies_count)).to include(0, 65).and(include(be_between(5, 15)))
    end

    it "keeps the forum counters in step with the seeded messages", :aggregate_failures do
      expect(general.topics_count).to eq(general.topics.count)
      expect(general.messages_count).to eq(general.messages.count)
      expect(general.last_message).to eq(general.messages.order(:id).last)
    end

    it "spreads the authors over several users" do
      expect(general.messages.distinct.count(:author_id)).to be >= 4
    end
  end
end
