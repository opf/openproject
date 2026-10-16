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

RSpec.describe DevelopmentData::ProjectsSeeder do
  include_context "with basic seed data"

  subject(:project_seeder) { described_class.new(seed_data.lookup("projects")) }

  let(:seed_data) do
    data = basic_seed_data.merge(
      Source::SeedData.new(
        "projects" => {}
      )
    )

    data
  end

  describe "#applicable?" do
    let(:project_admin_role) { build_stubbed(:project_role) }

    before do
      seed_data.store_reference(:default_role_project_admin, project_admin_role) if project_admin_role
    end

    context "with young projects already stored" do
      before { create(:project, created_at: 59.minutes.ago) }

      it "returns true" do
        expect(project_seeder).to be_applicable
      end
    end

    context "with a project having identifier 'dev-empty'" do
      before { create(:project, identifier: "dev-empty") }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "with a project having identifier 'dev-work-package-sharing'" do
      before { create(:project, identifier: "dev-work-package-sharing") }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "with a project having identifier 'dev-large'" do
      before { create(:project, identifier: "dev-large") }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "with a project having identifier 'dev-large-child'" do
      before { create(:project, identifier: "dev-large-child") }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "with a project having identifier 'dev-custom-fields'" do
      before { create(:project, identifier: "dev-custom-fields") }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "with a project older than 1 hour (regardless of the identifier)" do
      before { create(:project, created_at: 2.hours.ago) }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end

    context "without projects already stored but also with a missing reference to the default role" do
      let(:project_admin_role) { nil }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end
  end
end
