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

# `total` is user visible, in the API and in the work package table footer, so answering it from a
# short first page instead of a COUNT has to agree with that COUNT in every case, not only in the
# one it optimises.
RSpec.describe API::Decorators::OffsetPaginatedCollection, "total without a COUNT" do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:user) }
  shared_let(:work_packages) { create_list(:work_package, 5) }

  let(:page) { nil }
  let(:per_page) { nil }
  let(:models) { WorkPackage.all }

  # A representer that eager loads, which is the only case in which the number of rows the page
  # returned is known without a second query.
  let(:collection) do
    API::V3::WorkPackages::WorkPackageCollectionRepresenter.new(
      models,
      self_link: "/api/v3/example",
      query_params: {},
      project: nil,
      groups: nil,
      total_sums: nil,
      page:,
      per_page:,
      current_user: user,
      embed_schemas: false,
      timestamps: nil,
      query: nil
    )
  end

  def total_of(decorator)
    decorator.instance_variable_get(:@total)
  end

  def count_of_all_work_packages
    WorkPackage.count(:id)
  end

  current_user { user }

  before { mock_permissions_for(user, &:allow_everything) }

  context "when the first page is shorter than the page size" do
    let(:page) { 1 }
    let(:per_page) { 10 }

    it "reports the number of rows it actually got" do
      expect(total_of(collection)).to eq(5)
    end

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(count_of_all_work_packages)
    end

    it "does not issue a COUNT" do
      counted = []
      callback = ->(_, _, _, _, payload) { counted << payload[:sql] if payload[:sql]&.include?("COUNT") }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { total_of(collection) }

      expect(counted).to be_empty
    end
  end

  context "when the first page is exactly full" do
    let(:page) { 1 }
    let(:per_page) { 5 }

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(count_of_all_work_packages)
    end
  end

  context "when past the first page" do
    let(:page) { 2 }
    let(:per_page) { 3 }

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(count_of_all_work_packages)
    end
  end

  context "when the page size is zero" do
    let(:page) { 1 }
    let(:per_page) { 0 }

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(count_of_all_work_packages)
    end
  end

  # The eager loading wrapper plucks the ids and reloads them in a second query. A row deleted in
  # between -- or collapsed by the `where(id:)` dedup -- makes the array shorter than the page
  # actually was, and answering `total` from it would truncate the collection.
  context "when eager loading returns fewer objects than the page held" do
    let(:page) { 1 }
    let(:per_page) { 10 }

    before do
      drop_all_but_two = ->(method, ids, *args, **kwargs) { method.call(ids.first(2), *args, **kwargs) }

      allow(API::V3::WorkPackages::WorkPackageEagerLoadingWrapper)
        .to receive(:wrap).and_wrap_original(&drop_all_but_two)
    end

    it "still agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(count_of_all_work_packages)
    end
  end

  # Query::Results builds its relation with `eager_load`, so the COUNT being replaced is a
  # COUNT(DISTINCT id) while plucking the page returns one row per joined association row.
  context "when the relation eager loads a has-many" do
    let(:page) { 1 }
    let(:per_page) { 10 }
    let(:models) { WorkPackage.eager_load(:time_entries) }

    before { create_list(:time_entry, 2, entity: work_packages.first) }

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(models.count(:id))
    end

    it "agrees with the number of elements on the page" do
      expect(total_of(collection)).to eq(collection.represented.size)
    end
  end

  # Without eager loading rails does not add the DISTINCT, so the COUNT being replaced counts the
  # joined rows. Answering with the distinct count would make `total` depend on the page size.
  context "when the relation joins a has-many without eager loading" do
    let(:page) { 1 }
    let(:per_page) { 10 }
    let(:models) { WorkPackage.joins(:time_entries) }

    before { create_list(:time_entry, 2, entity: work_packages.first) }

    it "agrees with the COUNT it replaces" do
      expect(total_of(collection)).to eq(models.count(:id))
    end
  end

  # ProjectCollectionRepresenter and NotificationCollectionRepresenter hand the relation to their
  # wrapper instead of plucking ids, so no row count is recorded and the COUNT stays.
  context "with a representer that does not record a row count" do
    shared_let(:projects) { create_list(:project, 3) }

    let(:collection) do
      API::V3::Projects::ProjectCollectionRepresenter.new(
        Project.all,
        self_link: "/api/v3/projects",
        page: 1,
        per_page: 10,
        current_user: user
      )
    end

    it "falls back to the COUNT" do
      expect(total_of(collection)).to eq(Project.count(:id))
    end
  end
end
