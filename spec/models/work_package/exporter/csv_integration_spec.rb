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

RSpec.describe WorkPackage::Exports::CSV, "integration" do
  before do
    login_as user
  end

  shared_let(:project) { create(:project) }
  shared_let(:options) { { show_descriptions: true } }
  shared_let(:type_a) { create(:type, name: "Type A") }
  shared_let(:type_b) { create(:type, name: "Type B") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i(view_work_packages) })
  end

  before_all do
    set_factory_default(:user, user)
  end

  let(:instance) do
    described_class.new(query, options)
  end

  def byte_order_mark
    "\uFEFF"
  end

  context "when the query is default" do
    let(:query) do
      create(:query, project:, user:, column_names: %i(type subject assigned_to updated_at estimated_hours))
    end

    ##
    # When Ruby tries to join the following work package's subject encoded in ISO-8859-1
    # and its description encoded in UTF-8 it will result in a CompatibilityError.
    # This would not happen if the description contained only letters covered by
    # ISO-8859-1. Since this can happen, though, it is more sensible to encode everything
    # in UTF-8 which gets rid of this problem altogether.
    shared_let(:work_package) do
      create(
        :work_package,
        subject: "Ruby encodes ß as '\\xDF' in ISO-8859-1.",
        description: "\u2022 requires unicode.",
        assigned_to: user,
        estimated_hours: 10.0,
        derived_estimated_hours: 15.0,
        type: type_a,
        project:
      )
    end

    subject(:header_value_pairs) do
      data = CSV.parse instance.export!.content
      headers, values = data
      headers.zip(values)
    end

    context "when description is included" do
      it "performs a successful export with description column" do
        expect(header_value_pairs).to eq [
          ["#{byte_order_mark}Type", work_package.type.name],
          ["Subject", work_package.subject],
          ["Assignee", user.name],
          ["Updated on", work_package.updated_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y %I:%M %p")],
          ["Work", "10.0"],
          ["Total work", "15.0"],
          ["Description", work_package.description]
        ]
      end
    end

    context "when description is not included" do
      let(:options) { { show_descriptions: false } }

      it "performs a successful export without description column" do
        expect(header_value_pairs).to eq [
          ["#{byte_order_mark}Type", work_package.type.name],
          ["Subject", work_package.subject],
          ["Assignee", user.name],
          ["Updated on", work_package.updated_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y %I:%M %p")],
          ["Work", "10.0"],
          ["Total work", "15.0"]
        ]
      end
    end

    context "with a formula-injection payload in user-controlled fields",
            with_settings: { csv_escape_formulas: true } do
      shared_let(:work_package) do
        create(:work_package,
               subject: "=1+1",
               description: '=HYPERLINK("https://example.com","x")',
               type: type_a,
               project:)
      end

      it "escapes the formula cell by prepending a single quote" do
        pairs = header_value_pairs.to_h

        expect(pairs["Subject"]).to eq("'=1+1")
        expect(pairs["Description"]).to eq(%('=HYPERLINK("https://example.com","x")))
      end
    end
  end

  context "with semantic work package identifiers",
          with_settings: { work_packages_identifier: "semantic" } do
    let(:semantic_project) do
      create(:project,
             identifier: "CSVPROJ",
             member_with_permissions: { user => %i[view_work_packages] })
    end
    let!(:work_package) { create(:work_package, project: semantic_project) }
    let(:options) { {} }
    let(:query) do
      create(:query, project: semantic_project, user:, column_names: %i(id subject))
    end

    it "exports the semantic identifier in the ID column" do
      headers, values = CSV.parse instance.export!.content
      pairs = headers.zip(values).to_h

      expect(work_package.identifier).to match(/\ACSVPROJ-\d+\z/)
      # the leading ID header is downcased by the exporter to avoid SYLK detection
      expect(pairs["#{byte_order_mark}id"]).to eq work_package.identifier
      expect(pairs["Subject"]).to eq work_package.subject
    end
  end

  context "with multiple work packages" do
    shared_let(:wp1) { create(:work_package, project:, done_ratio: 25, subject: "WP1", type: type_a, id: 1) }
    shared_let(:wp2) { create(:work_package, project:, done_ratio: 0, subject: "WP2", type: type_a, id: 2) }
    shared_let(:wp3) { create(:work_package, project:, done_ratio: 0, subject: "WP3", type: type_b, id: 3) }
    shared_let(:wp4) { create(:work_package, project:, done_ratio: 0, subject: "WP4", type: type_a, id: 4) }

    context "when the query is grouped" do
      let(:query) do
        create(:query, project:, user:, column_names: %i(type subject id),
                       group_by: "type",
                       show_hierarchies: false, sort_criteria: [%w[type asc], %w[id asc]])
      end

      it "performs a successful grouped export" do
        type_a.update_column(:position, 1)
        type_b.update_column(:position, 2)
        data = CSV.parse instance.export!.content

        expect(data.size).to eq(5)
        expect(data.pluck(0)).to eq ["#{byte_order_mark}Type", "Type A", "Type A", "Type A", "Type B"]
      end
    end

    context "when the query is filtered" do
      let(:query) do
        create(:query, project:, user:, column_names: %i(subject done_ratio))
          .tap do |query|
          query.add_filter "done_ratio", "=", [25]
        end
      end

      it "performs a successful grouped export" do
        data = CSV.parse instance.export!.content

        expect(data.size).to eq(2)
        expect(data.last).to include(wp1.name)
      end
    end

    context "when the query is manually ordered" do
      let(:query) do
        create(
          :query, project:, user:,
                  column_names: %i(subject done_ratio),
                  sort_criteria: [[:manual_sorting, "asc"]]
        )
      end

      before do
        OrderedWorkPackage.delete_all
        OrderedWorkPackage.create(query:, work_package: wp4, position: 0)
        OrderedWorkPackage.create(query:, work_package: wp2, position: 1)
        OrderedWorkPackage.create(query:, work_package: wp1, position: 2)
        OrderedWorkPackage.create(query:, work_package: wp3, position: 3)
      end

      after do
        OrderedWorkPackage.delete_all
      end

      it "performs a successful manually ordered export" do
        data = CSV.parse instance.export!.content

        expect(data.size).to eq(5)
        expect(data.pluck(0)).to eq %w[WP4 WP2 WP1 WP3].unshift("#{byte_order_mark}Subject")
      end
    end
  end
end
