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
require Rails.root.join("db/migrate/20261117090000_backfill_categories_from_work_package.rb")

RSpec.describe BackfillCategoriesFromWorkPackage, type: :model do
  subject(:migrate) { run_migration }

  def run_migration = ActiveRecord::Migration.suppress_messages { described_class.new.up }

  let(:project) { create(:project) }
  let(:category) { create(:category, project:) }

  let!(:work_package_with_category) { create(:work_package, project:) }
  let!(:work_package_without_category) { create(:work_package, project:) }

  before { work_package_with_category.update_columns(category_id: category.id) }

  it "creates a row for each work package with a category" do
    migrate

    expect(WorkPackageCategory.where(work_package: work_package_with_category).pluck(:category_id))
      .to contain_exactly(category.id)
  end

  it "does not create rows for work packages without a category" do
    migrate

    expect(WorkPackageCategory.where(work_package: work_package_without_category)).to be_empty
  end

  it "skips category ids that point to a deleted category" do
    work_package_without_category.update_columns(category_id: 0)

    expect { migrate }.not_to raise_error
    expect(WorkPackageCategory.where(work_package: work_package_without_category)).to be_empty
  end

  it "is idempotent when run twice" do
    migrate

    expect { run_migration }
      .not_to change(WorkPackageCategory, :count)
  end
end
