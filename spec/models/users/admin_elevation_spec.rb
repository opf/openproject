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

RSpec.describe Users::AdminElevation do
  shared_let(:member_project) { create(:project) }
  shared_let(:elevated_project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  let(:project_id_column) { Project.arel_table[:id] }
  let(:admin_scope) { Project.where(id: [member_project, elevated_project, other_project]) }
  let(:member_scope) { Project.where(id: member_project) }

  def projects_matching(condition)
    Project.where(condition)
  end

  describe ".default" do
    it "is elevated everywhere with the feature flag inactive" do
      expect(described_class.default).to be_a(described_class::Everywhere)
    end

    it "is not elevated with the feature flag active", with_flag: { admin_privilege_elevation: true } do
      expect(described_class.default).to be_a(described_class::None)
    end
  end

  describe ".everywhere" do
    it "builds an Everywhere elevation" do
      expect(described_class.everywhere).to be_a(described_class::Everywhere)
    end
  end

  describe ".none" do
    it "builds a None elevation" do
      expect(described_class.none).to be_a(described_class::None)
    end
  end

  describe ".in_projects" do
    it "builds an InProjects elevation" do
      expect(described_class.in_projects([elevated_project.id])).to be_a(described_class::InProjects)
    end
  end

  describe ".from_h" do
    it "restores an Everywhere elevation" do
      expect(described_class.from_h(described_class.everywhere.to_h)).to be_a(described_class::Everywhere)
    end

    it "restores a None elevation" do
      expect(described_class.from_h(described_class.none.to_h)).to be_a(described_class::None)
    end

    it "restores an InProjects elevation with its projects", :aggregate_failures do
      elevation = described_class.from_h(described_class.in_projects([elevated_project.id]).to_h)

      expect(elevation).to be_a(described_class::InProjects)
      expect(elevation.covers?(elevated_project)).to be true
      expect(elevation.covers?(other_project)).to be false
    end

    it "restores an unknown type as no elevation" do
      expect(described_class.from_h({ "type" => "unknown" })).to be_a(described_class::None)
    end
  end

  describe ".for_session", with_flag: { admin_privilege_elevation: true } do
    shared_let(:admin) { create(:admin) }
    shared_let(:subproject) { create(:project, parent: elevated_project) }

    subject(:elevation) { described_class.for_session(admin, "session") }

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "is elevated everywhere" do
        expect(elevation).to be_a(described_class::Everywhere)
      end

      context "with an active elevation session in the session" do
        before { create(:admin_elevation_session, user: admin, project: elevated_project, session_id: "session") }

        it "is still elevated everywhere" do
          expect(elevation).to be_a(described_class::Everywhere)
        end
      end
    end

    context "without any elevation sessions" do
      it "is not elevated" do
        expect(elevation).to be_a(described_class::None)
      end
    end

    context "with an active elevation session in the session" do
      before { create(:admin_elevation_session, user: admin, project: elevated_project, session_id: "session") }

      it "covers the elevated project", :aggregate_failures do
        expect(elevation.covers?(elevated_project)).to be true
        expect(elevation.covers?(other_project)).to be false
      end

      it "does not cover the subprojects" do
        expect(elevation.covers?(subproject)).to be false
      end
    end

    context "with an active elevation session including subprojects" do
      before do
        create(:admin_elevation_session,
               user: admin, project: elevated_project, session_id: "session", include_subprojects: true)
      end

      it "covers the elevated project and its subprojects", :aggregate_failures do
        expect(elevation.covers?(elevated_project)).to be true
        expect(elevation.covers?(subproject)).to be true
        expect(elevation.covers?(other_project)).to be false
      end
    end

    context "with active elevation sessions for several projects in the session" do
      before do
        create(:admin_elevation_session, user: admin, project: elevated_project, session_id: "session")
        create(:admin_elevation_session, user: admin, project: other_project, session_id: "session")
      end

      it "covers all of them", :aggregate_failures do
        expect(elevation.covers?(elevated_project)).to be true
        expect(elevation.covers?(other_project)).to be true
        expect(elevation.covers?(member_project)).to be false
      end
    end

    context "with an ended elevation session in the session" do
      before do
        create(:admin_elevation_session,
               user: admin, project: elevated_project, session_id: "session", ended_at: Time.current)
      end

      it "is not elevated" do
        expect(elevation).to be_a(described_class::None)
      end
    end

    context "with an idle elevation session in the session" do
      before do
        create(:admin_elevation_session,
               user: admin, project: elevated_project, session_id: "session", last_used_at: 1.day.ago)
      end

      it "is not elevated" do
        expect(elevation).to be_a(described_class::None)
      end
    end

    context "with an active elevation session in another session" do
      before { create(:admin_elevation_session, user: admin, project: elevated_project, session_id: "other") }

      it "is not elevated" do
        expect(elevation).to be_a(described_class::None)
      end
    end

    context "with an active elevation session of another admin in the session" do
      before { create(:admin_elevation_session, project: elevated_project, session_id: "session") }

      it "is not elevated" do
        expect(elevation).to be_a(described_class::None)
      end
    end
  end

  describe Users::AdminElevation::Everywhere do
    subject(:elevation) { described_class.new }

    it "covers every project" do
      expect(elevation.covers?(other_project)).to be true
    end

    it "builds a condition matching every project" do
      expect(projects_matching(elevation.project_condition(project_id_column)))
        .to contain_exactly(member_project, elevated_project, other_project)
    end

    it "uses the admin scope" do
      expect(elevation.allowed_scope(admin_scope:, member_scope:, project_id_column: :id))
        .to contain_exactly(member_project, elevated_project, other_project)
    end
  end

  describe Users::AdminElevation::None do
    subject(:elevation) { described_class.new }

    it "covers no project" do
      expect(elevation.covers?(member_project)).to be false
    end

    it "builds a condition matching no project" do
      expect(projects_matching(elevation.project_condition(project_id_column))).to be_empty
    end

    it "uses the member scope" do
      expect(elevation.allowed_scope(admin_scope:, member_scope:, project_id_column: :id))
        .to contain_exactly(member_project)
    end
  end

  describe Users::AdminElevation::InProjects do
    subject(:elevation) { described_class.new([elevated_project.id]) }

    it "covers the elevated project" do
      expect(elevation.covers?(elevated_project)).to be true
    end

    it "does not cover other projects" do
      expect(elevation.covers?(other_project)).to be false
    end

    it "builds a condition matching only the elevated project" do
      expect(projects_matching(elevation.project_condition(project_id_column)))
        .to contain_exactly(elevated_project)
    end

    it "combines the member scope with the elevated projects of the admin scope" do
      expect(elevation.allowed_scope(admin_scope:, member_scope:, project_id_column: :id))
        .to contain_exactly(member_project, elevated_project)
    end

    context "without any project ids" do
      subject(:elevation) { described_class.new([]) }

      it "builds a condition matching no project" do
        expect(projects_matching(elevation.project_condition(project_id_column))).to be_empty
      end

      it "uses only the member scope" do
        expect(elevation.allowed_scope(admin_scope:, member_scope:, project_id_column: :id))
          .to contain_exactly(member_project)
      end
    end
  end
end
