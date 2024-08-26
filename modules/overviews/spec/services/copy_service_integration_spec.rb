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

RSpec.describe Projects::CopyService, "integration", type: :model do
  shared_let(:source) { create(:project, enabled_module_names: %w[wiki work_package_tracking]) }
  shared_let(:source_category) { create(:category, project: source, name: "Stock management") }
  shared_let(:source_version) { create(:version, project: source, name: "Version A") }

  let(:current_user) do
    create(:user,
           member_with_roles: { source => role })
  end
  let(:role) { create(:project_role, permissions: %i[copy_projects]) }
  let(:instance) do
    described_class.new(source:, user: current_user)
  end
  let(:only_args) { nil }
  let(:target_project_params) do
    { name: "Some name", identifier: "some-identifier" }
  end
  let(:params) do
    { target_project_params:, only: only_args }
  end

  describe "call" do
    subject { instance.call(params) }

    let(:project_copy) { subject.result }

    describe "overview" do
      let(:widget_data) do
        [
          [[1, 1, 1, 2], "project_description", {}],
          [[1, 1, 3, 4], "project_status", {}],
          [[2, 2, 1, 2], "members", { "name" => "Members" }]
        ]
      end

      let(:original_overview) do
        widgets = widget_data.map do |layout, identifier, options|
          build(
            :grid_widget,
            identifier:,
            options:,
            start_row: layout[0],
            end_row: layout[1],
            start_column: layout[2],
            end_column: layout[3]
          )
        end

        create(:overview, project: source, widgets:, column_count: 2, row_count: (widgets.size / 2) + 1)
      end

      let(:overview) { Grids::Overview.find_by(project: project_copy) }

      context "when requested" do
        let(:only_args) { %i[work_packages overview] }

        before do
          original_overview

          expect(subject).to be_success
        end

        it "is copied" do
          expect(overview.widgets.size).to eq original_overview.widgets.size
        end
      end

      context "when not requested" do
        let(:only_args) { %i[work_packages] }

        before do
          original_overview

          expect(subject).to be_success
        end

        it "is ignored" do
          expect(overview).to be_nil
        end
      end

      describe "copy" do
        let(:only_args) { %i[versions categories overview] }

        before do
          original_overview

          expect(subject).to be_success
        end

        it "contains the same widgets" do
          expect(overview.widgets.size).to eq original_overview.widgets.size

          fields = %i(identifier options start_row end_row start_column end_column)

          fields.each do |field|
            expect(overview.widgets.map(&field)).to eq original_overview.widgets.map(&field)
          end
        end

        context "with references" do
          describe "to queries" do
            let!(:query) do
              create(:public_query, project: source).tap do |query|
                query.add_filter "version_id", "=", [source_version.id.to_s]
                query.add_filter "category_id", "=", [source_category.id.to_s]
                query.save!
              end
            end

            let(:widget_data) do
              [
                [[1, 1, 1, 2], "work_packages_table", { "queryId" => query.id.to_s }]
              ]
            end

            it "copies the widgets and updates references to copied queries" do
              expect(overview.widgets.size).to eq original_overview.widgets.size

              overview.widgets.zip(original_overview.widgets).each do |widget, original_widget|
                query = Query.find widget.options["queryId"]
                original_query = Query.find original_widget.options["queryId"]

                expect(query.id).not_to eq original_query.id
                expect(query.name).to eq original_query.name

                expect(query.filters.map(&:name)).to eq original_query.filters.map(&:name)
                expect(query.filters.map(&:operator)).to eq original_query.filters.map(&:operator)
              end
            end

            it "updates references within the copied query" do
              query_copy = Query.where(name: query.name, project: project_copy).first

              expect(query_copy).to be_present

              version_copy = Version.find query_copy.filters.find { |f| f.name == :version_id }.values.first

              expect(version_copy.id).not_to eq source_version.id
              expect(version_copy.name).to eq source_version.name

              category_copy = Category.find query_copy.filters.find { |f| f.name == :category_id }.values.first

              expect(category_copy.id).not_to eq source_category.id
              expect(category_copy.name).to eq source_category.name
            end
          end
        end
      end
    end
  end
end
