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

RSpec.describe Grids::UpdateContract, "for Grids::Overview" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:current_user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_project manage_dashboards view_work_packages save_queries manage_public_queries]
           })
  end
  shared_let(:other_user) { create(:user) }

  let(:own_query) { create(:query, project:, user: current_user) }
  let(:grid) { create(:overview, project:) }
  let(:instance) { described_class.new(grid, current_user) }
  let(:identifier) { "work_packages_table" }

  def build_widget(options)
    grid.widgets.build(identifier:,
                       start_row: 1,
                       end_row: 2,
                       start_column: 1,
                       end_column: 2,
                       options:)
  end

  shared_examples "valid" do
    it "is valid" do
      expect(instance.validate).to be_truthy
    end
  end

  shared_examples "invalid query" do
    it "reports an error on widgets" do
      instance.validate

      expect(instance.errors.symbols_for(:widgets))
        .to contain_exactly(:invalid_query)
    end
  end

  shared_examples "unchangeable query" do
    it "reports an error on widgets" do
      instance.validate

      expect(instance.errors.symbols_for(:widgets))
        .to contain_exactly(:query_unchangeable)
    end
  end

  context "when adding a widget" do
    before do
      build_widget({ "name" => "Widget", "queryId" => query_id })
    end

    context "with a query of the current user in the project" do
      let(:query_id) { own_query.id.to_s }

      it_behaves_like "valid"
    end

    context "with a query in another project" do
      let(:query_id) { create(:query, project: other_project, user: current_user).id.to_s }

      it_behaves_like "invalid query"
    end

    context "with a query of another user in the project" do
      let(:query_id) { create(:query, project:, user: other_user, public: true).id.to_s }

      it_behaves_like "invalid query"
    end

    context "with a global query" do
      let(:query_id) { create(:query, project: nil, user: current_user).id.to_s }

      it_behaves_like "invalid query"
    end

    context "with a non existing query" do
      let(:query_id) { "0" }

      it_behaves_like "invalid query"
    end

    context "without a query" do
      let(:query_id) { nil }

      it_behaves_like "valid"
    end

    context "with a foreign query on a widget other than the table" do
      let(:identifier) { "work_packages_graph" }
      let(:query_id) { create(:query, project: other_project, user: current_user).id.to_s }

      it_behaves_like "invalid query"
    end
  end

  context "when updating a persisted widget referencing a query of another user" do
    let(:foreign_query) { create(:query, project:, user: other_user, public: true) }
    let!(:widget) do
      build_widget({ "name" => "Widget", "queryId" => foreign_query.id.to_s }).tap { grid.save!(validate: false) }
    end

    context "when altering only the name and position" do
      before do
        widget.options = widget.options.merge("name" => "Renamed")
        widget.end_row = 3
      end

      it_behaves_like "valid"
    end

    context "when changing the query to an own query" do
      before do
        widget.options = widget.options.merge("queryId" => own_query.id.to_s)
      end

      it_behaves_like "unchangeable query"
    end

    context "when removing the query" do
      before do
        widget.options = widget.options.except("queryId")
      end

      it_behaves_like "unchangeable query"
    end
  end

  context "when setting the query on a persisted widget without one" do
    let!(:widget) do
      build_widget({ "name" => "Widget" }).tap { grid.save!(validate: false) }
    end

    before do
      widget.options = widget.options.merge("queryId" => query_id)
    end

    context "with a query of the current user in the project" do
      let(:query_id) { own_query.id.to_s }

      it_behaves_like "valid"
    end

    context "with a query in another project" do
      let(:query_id) { create(:query, project: other_project, user: current_user).id.to_s }

      it_behaves_like "invalid query"
    end
  end
end
