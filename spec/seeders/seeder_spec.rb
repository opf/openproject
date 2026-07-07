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

RSpec.describe Seeder do
  subject(:seeder) { described_class.new }

  let(:seed_data) { Source::SeedData.new({}) }

  describe "#admin_user" do
    it "returns the admin created from the seeding" do
      expect(seeder.admin_user).to be_nil
      AdminUserSeeder.new(seed_data).seed!
      expect(seeder.admin_user).to be_a(User)
    end

    it "does not return the system user" do
      expect { User.system }.to change { User.admin.count }.by(1)
      expect(seeder.admin_user).to be_nil
    end
  end

  describe "#seed_project_identifier" do
    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "returns the given identifier verbatim" do
        expect(seeder.seed_project_identifier("dev-resource-management")).to eq("dev-resource-management")
      end
    end

    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "derives an identifier that satisfies the semantic format" do
        %w[dev-resource-management demo-project your-scrum-project dev-work-package-sharing].each do |identifier|
          derived = seeder.seed_project_identifier(identifier)

          expect(derived).to match(/\A[A-Z][A-Z0-9_]*\z/)
          expect(derived.length).to be <= Projects::Identifier::SEMANTIC_IDENTIFIER_MAX_LENGTH
        end
      end

      it "maps a given identifier to the same value on every call" do
        derived = seeder.seed_project_identifier("demo-construction-project")

        expect(seeder.seed_project_identifier("demo-construction-project")).to eq(derived)
      end

      it "does not consult existing projects when deriving the value" do
        first = seeder.seed_project_identifier("demo-project")
        create(:project, identifier: first)

        expect(seeder.seed_project_identifier("demo-project")).to eq(first)
      end
    end

    it "leaves a blank identifier untouched so the model can generate one" do
      expect(seeder.seed_project_identifier(nil)).to be_nil
    end
  end
end
