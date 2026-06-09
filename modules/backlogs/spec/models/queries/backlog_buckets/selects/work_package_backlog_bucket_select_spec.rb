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

RSpec.describe OpenProject::Backlogs::WorkPackageBacklogBucketSelect do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".instances" do
    context "when user has permission to view sprints in a project" do
      let(:project) { build_stubbed(:project, enabled_module_names: %w[backlogs]) }

      current_user { build_stubbed(:user) }

      before do
        mock_permissions_for current_user do |mock|
          mock.allow_in_project(:view_sprints, project:)
        end
      end

      it "returns backlog bucket select instances" do
        instances = described_class.instances(project)

        expect(instances).to be_an(Array)
        expect(instances.size).to eq(1)
        expect(instances.first.name).to eq(:backlog_bucket)
      end
    end

    context "when user has permission to view sprints in any project" do
      current_user { build_stubbed(:user) }

      before do
        mock_permissions_for current_user do |mock|
          mock.allow_in_project(:view_sprints, project: build_stubbed(:project))
        end
      end

      it "returns backlog bucket select instances when no context provided" do
        instances = described_class.instances

        expect(instances).to be_an(Array)
        expect(instances.size).to eq(1)
        expect(instances.first.name).to eq(:backlog_bucket)
      end
    end

    context "when user lacks permission to view sprints in a(ny) project" do
      let(:project) { build_stubbed(:project, enabled_module_names: %w[backlogs]) }

      current_user { build_stubbed(:user) }

      before do
        mock_permissions_for current_user do |mock|
          # No permissions granted
        end
      end

      it "returns an empty array" do
        # Lacking permission in a project
        expect(described_class.instances(project)).to eq([])

        # Lacking permission in any project
        expect(described_class.instances).to eq([])
      end
    end

    context "when backlogs module is not enabled for the project" do
      let(:project) { build_stubbed(:project, enabled_module_names: []) }

      current_user { build_stubbed(:user) }

      before do
        mock_permissions_for current_user do |mock|
          mock.allow_in_project(:view_sprints, project:)
        end
      end

      it "returns an empty array" do
        instances = described_class.instances(project)

        expect(instances).to eq([])
      end
    end
  end
end
