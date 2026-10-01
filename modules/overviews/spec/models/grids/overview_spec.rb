# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Grids::Overview do
  let(:instance) { described_class.new(row_count: 5, column_count: 5) }

  context "when altering widgets" do
    shared_examples_for "removing a query widget" do |identifier|
      let(:project) { create(:project) }
      let(:query) do
        create(:query,
               public: true,
               project:)
      end

      current_user { build_stubbed(:user) }

      before do
        widget = Grids::Widget.new(identifier:,
                                   start_row: 1,
                                   end_row: 2,
                                   start_column: 1,
                                   end_column: 2,
                                   options: { "queryId" => query.id })

        instance.widgets = [widget]
        instance.save!
      end

      context "when the current user has the permission to manage public queries" do
        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project :manage_public_queries, project:
          end
        end

        it "removes the widget's query" do
          instance.widgets = []

          expect(Query.find_by(id: query.id))
            .to be_nil
        end
      end

      context "when the current user lacks the permission to manage public queries" do
        current_user { create(:user) }

        it "removes the widget but keeps the query" do
          instance.widgets = []

          expect(Query.find_by(id: query.id))
            .to eql query
        end
      end
    end

    it_behaves_like "removing a query widget", "work_packages_table"
    it_behaves_like "removing a query widget", "work_packages_graph"
  end
end
