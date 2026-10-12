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

RSpec.describe AdminElevationSession do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
  end

  describe "validations" do
    subject(:elevation_session) { build(:admin_elevation_session, user: admin, project:) }

    it "is valid with the factory defaults" do
      expect(elevation_session).to be_valid
    end

    it "requires a session id" do
      elevation_session.session_id = nil

      expect(elevation_session).not_to be_valid
    end

    it "requires a known confirmation method" do
      elevation_session.confirmed_with = "magic"

      expect(elevation_session).not_to be_valid
    end

    %w[two_factor password confirmation].each do |method|
      it "accepts #{method} as confirmation method" do
        elevation_session.confirmed_with = method

        expect(elevation_session).to be_valid
      end
    end
  end

  describe "#last_used_at" do
    it "defaults to the time of creation" do
      freeze_time do
        expect(described_class.new.last_used_at).to eq(Time.current)
      end
    end
  end

  describe ".for_session" do
    let!(:own_session) { create(:admin_elevation_session, user: admin, project:, session_id: "own") }
    let!(:other_session) { create(:admin_elevation_session, user: admin, project:, session_id: "other") }

    it "returns the elevation sessions of the given session id" do
      expect(described_class.for_session("own")).to contain_exactly(own_session)
    end
  end

  describe ".active", with_settings: { admin_elevation_idle_timeout: 30 } do
    let!(:recently_used) { create(:admin_elevation_session, user: admin, project:, last_used_at: 29.minutes.ago) }
    let!(:idle) { create(:admin_elevation_session, user: admin, project:, last_used_at: 31.minutes.ago) }
    let!(:ended) do
      create(:admin_elevation_session, user: admin, project:, last_used_at: 1.minute.ago, ended_at: Time.current)
    end

    it "returns the elevation sessions used within the idle timeout that have not ended" do
      expect(described_class.active).to contain_exactly(recently_used)
    end

    context "with a shorter idle timeout", with_settings: { admin_elevation_idle_timeout: 10 } do
      it "excludes elevation sessions idle for longer" do
        expect(described_class.active).to be_empty
      end
    end
  end

  describe "#project_ids" do
    shared_let(:child) { create(:project, parent: project) }
    shared_let(:grandchild) { create(:project, parent: child) }
    shared_let(:sibling) { create(:project) }

    let(:elevation_session) do
      build(:admin_elevation_session, user: admin, project:, include_subprojects:)
    end

    context "without including subprojects" do
      let(:include_subprojects) { false }

      it "is only the project" do
        expect(elevation_session.project_ids).to contain_exactly(project.id)
      end
    end

    context "with including subprojects" do
      let(:include_subprojects) { true }

      it "is the project and all its descendants" do
        expect(elevation_session.project_ids).to contain_exactly(project.id, child.id, grandchild.id)
      end
    end
  end

  describe "#expires_at", with_settings: { admin_elevation_idle_timeout: 30 } do
    it "is the idle timeout after the last use" do
      last_used_at = Time.zone.local(2026, 10, 12, 12, 0)
      elevation_session = build(:admin_elevation_session, last_used_at:)

      expect(elevation_session.expires_at).to eq(last_used_at + 30.minutes)
    end
  end

  describe "#active?", with_settings: { admin_elevation_idle_timeout: 30 } do
    it "is true when used within the idle timeout and not ended" do
      expect(build(:admin_elevation_session, last_used_at: 29.minutes.ago)).to be_active
    end

    it "is false when idle for longer than the timeout" do
      expect(build(:admin_elevation_session, last_used_at: 31.minutes.ago)).not_to be_active
    end

    it "is false when ended" do
      expect(build(:admin_elevation_session, ended_at: Time.current)).not_to be_active
    end
  end

  describe "#use!" do
    let(:elevation_session) { create(:admin_elevation_session, user: admin, project:, last_used_at: 10.minutes.ago) }

    it "moves the last use to now" do
      freeze_time do
        elevation_session.use!

        expect(elevation_session.reload.last_used_at).to eq(Time.current)
      end
    end
  end

  describe "#end!" do
    let(:elevation_session) { create(:admin_elevation_session, user: admin, project:) }

    it "sets the end to now" do
      freeze_time do
        elevation_session.end!

        expect(elevation_session.reload.ended_at).to eq(Time.current)
      end
    end

    it "makes the elevation session inactive" do
      elevation_session.end!

      expect(described_class.active).not_to include(elevation_session)
    end
  end
end
