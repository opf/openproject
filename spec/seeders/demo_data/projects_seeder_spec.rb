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

RSpec.describe DemoData::ProjectsSeeder do
  include_context "with basic seed data"

  subject(:project_seeder) { described_class.new(seed_data) }

  let(:seed_data) do
    data = basic_seed_data.merge(
      Source::SeedData.new(
        "projects" => {
          "my-project" => project_data
        }
      )
    )

    data
  end

  let(:project_data) do
    YAML.load <<~SEEDING_DATA_YAML
      name: 'Some project'
      types:
        - :type_task
    SEEDING_DATA_YAML
  end

  describe "#applicable?" do
    let(:project_admin_role) { build_stubbed(:project_role) }
    let(:type_task) { build_stubbed(:type) }

    before do
      seed_data.store_reference(:default_role_project_admin, project_admin_role) if project_admin_role
      seed_data.store_reference(:type_task, type_task) if type_task
    end

    context "without projects already stored" do
      it "returns true" do
        expect(project_seeder).to be_applicable
      end
    end

    context "with projects already stored" do
      before { create(:project) }

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

    context "without projects already stored but also with a missing reference to one of the types" do
      let(:type_task) { nil }

      it "returns false" do
        expect(project_seeder).not_to be_applicable
      end
    end
  end
end
