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

RSpec.describe WorkPackage::Categories do
  let(:work_package) { create(:work_package) }
  let(:project) { work_package.project }

  describe "#categories" do
    let!(:zeta) { create(:category, project:, name: "zeta") }
    let!(:alpha) { create(:category, project:, name: "Alpha") }
    let!(:beta) { create(:category, project:, name: "beta") }

    before do
      [beta, zeta, alpha].each { |category| create(:work_package_category, work_package:, category:) }
    end

    it "returns the categories ordered by id" do
      expect(work_package.reload.categories).to eq [zeta, alpha, beta]
    end
  end

  it "deletes the category associations together with the work package" do
    create(:work_package_category, work_package:)

    expect { work_package.destroy }.to change(WorkPackageCategory, :count).by(-1)
  end

  describe "mirroring" do
    let(:backend) { create(:category, project:, name: "Backend") }
    let(:frontend) { create(:category, project:, name: "Frontend") }
    let(:api) { create(:category, project:, name: "api") }

    context "when writing category_ids_replacements" do
      before do
        work_package.category_ids_replacements = [frontend.id, api.id, backend.id]
        work_package.save!
      end

      it "stores the categories in the join table" do
        expect(work_package.reload.categories).to contain_exactly(api, backend, frontend)
      end

      it "mirrors the first category in alphabetical order into category_id" do
        expect(work_package.reload.category_id).to eq api.id
      end

      it "clears the replacements after the save" do
        expect(work_package.override_categories?).to be false
      end

      it "replaces the set on the next write" do
        work_package.category_ids_replacements = [backend.id]

        expect { work_package.save! }
          .to change { work_package.reload.categories.to_a }.from(contain_exactly(api, backend, frontend)).to([backend])
          .and change { work_package.reload.category_id }.from(api.id).to(backend.id)
      end

      it "removes all categories with an empty list" do
        work_package.category_ids_replacements = []

        expect { work_package.save! }
          .to change { work_package.reload.categories.to_a }.from(contain_exactly(api, backend, frontend)).to([])
          .and change { work_package.reload.category_id }.from(api.id).to(nil)
      end
    end

    context "when writing category_id" do
      it "mirrors a set category into the join table" do
        work_package.update!(category: backend)

        expect(work_package.reload.categories).to contain_exactly(backend)
      end

      it "mirrors a changed category into the join table" do
        work_package.update!(category: backend)

        expect { work_package.update!(category: frontend) }
          .to change { work_package.reload.categories.to_a }.from([backend]).to([frontend])
      end

      it "mirrors a removed category into the join table" do
        work_package.update!(category: backend)

        expect { work_package.update!(category: nil) }
          .to change { work_package.reload.categories.to_a }.from([backend]).to([])
      end
    end

    it "keeps the join table untouched when the category does not change" do
      work_package.update!(category: backend)

      expect { work_package.update!(subject: "Changed") }
        .not_to change { work_package.work_package_categories.reload.ids }
    end
  end
end
