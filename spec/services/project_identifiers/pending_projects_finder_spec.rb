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

require "rails_helper"

RSpec.describe ProjectIdentifiers::PendingProjectsFinder,
               with_settings: { work_packages_identifier: "classic" } do
  describe ".count" do
    context "when everything is clean" do
      it "returns 0" do
        expect(described_class.count).to eq(0)
      end
    end

    context "when projects span multiple buckets" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "VALID1") }
      end
      let!(:wp) { create(:work_package, project:) }

      it "counts each project once regardless of how many buckets it appears in" do
        expect(described_class.count).to eq(1)
      end
    end

    context "when projects are in distinct buckets" do
      let!(:project_bad_id) { create(:project, name: "Bad Identifier") }
      let!(:project_unsequenced) do
        create(:project).tap { |p| p.update_columns(identifier: "VALID1", wp_sequence_counter: 1) }
      end
      let!(:unsequenced_wp) { create(:work_package, project: project_unsequenced) }

      it "counts all pending projects" do
        expect(described_class.count).to eq(2)
      end
    end
  end

  describe ".project_ids" do
    context "when everything is clean" do
      it "returns an empty set" do
        expect(described_class.project_ids).to be_empty
      end
    end

    context "when a project has a non-semantic identifier" do
      let!(:project) { create(:project, name: "My Project") }

      it "includes that project" do
        expect(described_class.project_ids).to include(project.id)
      end
    end

    context "when a project has a valid identifier but work packages without sequence numbers" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "VALID1") }
      end
      let!(:wp) { create(:work_package, project:) }

      it "includes that project" do
        expect(described_class.project_ids).to include(project.id)
      end
    end

    context "when a project has a valid identifier but no work packages needing backfill" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "VALID1", wp_sequence_counter: 1) }
      end
      let!(:wp) { create(:work_package, project:).tap { |w| w.update_columns(sequence_number: 1, identifier: "VALID1-1") } }

      it "does not include that project" do
        expect(described_class.project_ids).not_to include(project.id)
      end
    end

    context "when a project has work packages with stale identifiers" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "DEST", wp_sequence_counter: 1) }
      end
      let!(:wp) { create(:work_package, project:).tap { |w| w.update_columns(sequence_number: 1, identifier: "SOURCE-1") } }

      it "includes that project" do
        expect(described_class.project_ids).to include(project.id)
      end
    end
  end
end
