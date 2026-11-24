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

RSpec.describe "Work package visibility with security levels" do # rubocop:disable RSpec/DescribeClass
  shared_let(:scheme) { create(:security_level_scheme) }
  shared_let(:project) { create(:project, security_level_scheme: scheme) }
  shared_let(:internal) { create(:security_level, security_level_scheme: scheme, name: "Internal") }
  shared_let(:management) { create(:security_level, security_level_scheme: scheme, name: "Management") }

  shared_let(:unsecured_wp) { create(:work_package, project:) }
  shared_let(:internal_wp) { create(:work_package, project:, security_level: internal) }
  shared_let(:management_wp) { create(:work_package, project:, security_level: management) }

  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }

  subject(:visible) { WorkPackage.visible(user) }

  context "when the user holds no level" do
    it "sees only work packages without a level" do
      expect(visible).to contain_exactly(unsecured_wp)
    end

    it "is denied the secured work packages on single record checks" do
      expect(user.allowed_in_work_package?(:view_work_packages, internal_wp)).to be false
      expect(user.allowed_in_work_package?(:edit_work_packages, internal_wp)).to be false
      expect(user.allowed_in_work_package?(:view_work_packages, unsecured_wp)).to be true
      expect(internal_wp.visible?(user)).to be false
    end
  end

  context "when the user holds a level directly" do
    before { SecurityLevelPrincipal.create!(security_level: internal, principal: user) }

    it "sees the work packages of that level" do
      expect(visible).to contain_exactly(unsecured_wp, internal_wp)
      expect(user.allowed_in_work_package?(:view_work_packages, internal_wp)).to be true
      expect(user.allowed_in_work_package?(:view_work_packages, management_wp)).to be false
    end
  end

  context "when the user holds a level through a group" do
    before do
      group = create(:group, members: [user])
      SecurityLevelPrincipal.create!(security_level: management, principal: group)
    end

    it "sees the work packages of that level" do
      expect(visible).to contain_exactly(unsecured_wp, management_wp)
    end
  end

  context "when a work package is shared with the user" do
    before do
      create(:work_package_member, entity: management_wp, user:,
                                   roles: [create(:view_work_package_role)])
    end

    it "keeps the level in force" do
      expect(visible).not_to include(management_wp)
    end
  end

  context "when the user is an admin" do
    let(:user) { create(:admin) }

    it "sees every work package" do
      expect(visible).to contain_exactly(unsecured_wp, internal_wp, management_wp)
      expect(user.allowed_in_work_package?(:view_work_packages, management_wp)).to be true
    end
  end

  context "when the user is anonymous" do
    let(:user) { User.anonymous }

    before do
      project.update!(public: true)
      create(:anonymous_role, permissions: %i[view_work_packages])
    end

    it "sees only work packages without a level" do
      expect(visible).to contain_exactly(unsecured_wp)
    end
  end

  describe "historic values (journal timeline)" do
    let(:timeline_work_packages) do
      WorkPackages::JournalTimeline
        .new(Journal::WorkPackageJournal.where(project_id: project.id), ticks: [Time.current], user:)
        .relation
        .distinct
        .pluck(:work_package_id)
    end

    it "omits work packages hidden today, even where an older version had no level" do
      unsecured_wp.update_column(:security_level_id, management.id)

      expect(timeline_work_packages).to be_empty
    end

    it "includes them for a user holding the level" do
      SecurityLevelPrincipal.create!(security_level: internal, principal: user)

      expect(timeline_work_packages).to contain_exactly(unsecured_wp.id, internal_wp.id)
    end
  end

  describe "the generated SQL" do
    before { SecurityLevelPrincipal.create!(security_level: internal, principal: user) }

    it "filters on plucked level ids without joining the level tables" do
      sql = visible.to_sql

      expect(sql).to include(%{"work_packages"."security_level_id" IS NULL})
      expect(sql).to include(%{"work_packages"."security_level_id" IN (#{internal.id})})
      expect(sql).not_to include("security_level_principals")
    end

    it "looks up the user's levels once per user instance" do
      user.reload
      level_queries = []
      callback = ->(*, payload) { level_queries << payload[:sql] if payload[:sql].include?("security_level_principals") }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        3.times { WorkPackage.visible(user).load }
      end

      expect(level_queries.size).to eq 1
    end
  end
end
