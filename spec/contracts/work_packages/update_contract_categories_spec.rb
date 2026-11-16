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
require "contracts/shared/model_contract_shared_context"

RSpec.describe WorkPackages::UpdateContract, "categories" do
  include_context "ModelContract shared context"

  subject(:contract) { described_class.new(work_package, admin) }

  shared_let(:admin) { create(:admin) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:backend) { create(:category, project:, name: "Backend") }
  let(:frontend) { create(:category, project:, name: "Frontend") }
  let(:foreign_category) { create(:category) }

  it "is valid without category replacements" do
    expect_contract_valid
  end

  it "is valid with a category of the project" do
    work_package.category_ids_replacements = [backend.id]

    expect_contract_valid
  end

  it "is valid with an empty list" do
    work_package.category_ids_replacements = []

    expect_contract_valid
  end

  it "is invalid with a category of another project" do
    work_package.category_ids_replacements = [foreign_category.id]

    expect_contract_invalid(categories: :inclusion)
  end

  context "with several categories" do
    before { work_package.category_ids_replacements = [backend.id, frontend.id] }

    it "is invalid while multiple categories is off",
       with_flag: { work_package_multiple_categories: false },
       with_settings: { work_package_multiple_categories: false } do
      expect_contract_invalid(base: :categories_only_allow_single_value)
    end

    it "is valid while multiple categories is on",
       with_settings: { work_package_multiple_categories: true } do
      expect_contract_valid
    end
  end

  context "when category_id is also set" do
    it "is valid when category_id is the first category in alphabetical order",
       with_settings: { work_package_multiple_categories: true } do
      work_package.category_ids_replacements = [frontend.id, backend.id]
      work_package.category_id = backend.id

      expect_contract_valid
    end

    it "is invalid when category_id differs from the first category" do
      work_package.category_ids_replacements = [backend.id]
      work_package.category_id = frontend.id

      expect_contract_invalid(base: :category_and_categories_mutually_exclusive)
    end
  end
end
