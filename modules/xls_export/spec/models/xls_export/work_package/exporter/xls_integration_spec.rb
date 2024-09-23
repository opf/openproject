require "spec_helper"
require "spreadsheet"

RSpec.describe XlsExport::WorkPackage::Exporter::XLS do
  shared_let(:project) { create(:project) }
  shared_let(:admin) { create(:admin) }

  let(:current_user) { admin }

  let(:column_names) { %w[type id subject status assigned_to priority] }
  let(:query) do
    query = build(:query, user: current_user, project:)

    query.filters.clear
    query.column_names = column_names
    query.sort_criteria = [["id", "asc"]]
    query
  end

  let(:relations) { [] }

  let(:sheet) do
    login_as(current_user)
    work_packages
    relations
    work_packages.each(&:reload) # to init .leaves and relations
    io = StringIO.new export.export!.content
    Spreadsheet.open(io).worksheets.first
  end

  let(:options) { {} }

  let(:export) do
    described_class.new(
      query,
      options
    )
  end

  context "with relations" do
    let(:options) { { show_relations: "true" } }

    let(:parent) { create(:work_package, project:, subject: "Parent") }
    let(:child_1) do
      create(:work_package, parent:, project:, subject: "Child 1")
    end
    let(:child_2) do
      create(:work_package, parent:, project:, subject: "Child 2")
    end

    let(:single) { create(:work_package, project:, subject: "Single") }
    let(:followed) { create(:work_package, project:, subject: "Followed") }

    let(:child_2_child) do
      create(:work_package, parent: child_2, project:, subject: "Child 2's child")
    end

    let(:relation) do
      create(:follows_relation, from: child_2, to: followed, description: "description foobar")
    end

    let(:relations) { [relation] }

    let(:work_packages) do
      work_packages = [parent, child_1, child_2, single, followed]
      child_2_child

      work_packages
    end
    # expected row and column indices

    PARENT = 2
    CHILD_1 = 4
    CHILD_2 = 5
    SINGLE = 8
    FOLLOWED = 9
    RELATION = 8
    RELATION_DESCRIPTION = 10
    RELATED_SUBJECT = 13

    it "produces the correct result" do
      expect(query.columns.map(&:name)).to eq %i[type id subject status assigned_to priority]

      # the first header row divides the sheet into work packages and relation columns
      expect(sheet.rows.first.take(8)).to eq ["Work packages", nil, nil, nil, nil, nil, nil, "Relations"]

      # the second header row includes the column names for work packages and relations and the related work package
      expect(sheet.rows[1])
        .to eq [
          nil, "Type", "ID", "Subject", "Status", "Assignee", "Priority",
          nil, "Relation type", "Lag", "Description",
          "Type", "ID", "Subject", "Status", "Assignee", "Priority",
          nil
        ]

      # duplicates rows for each relation
      c2id = child_2.id
      expect(sheet.column(2).drop(2))
        .to eq [parent.id, parent.id, child_1.id, c2id, c2id, c2id, single.id, followed.id, child_2_child.id].map(&:to_s)

      # marks Parent as parent of Child 1 and 2
      expect(sheet.row(PARENT)[RELATION]).to eq "parent of"
      expect(sheet.row(PARENT)[RELATED_SUBJECT]).to eq "Child 1"

      expect(sheet.row(PARENT + 1)[RELATION]).to eq "parent of"
      expect(sheet.row(PARENT + 1)[RELATED_SUBJECT]).to eq "Child 2"

      # shows Child 1 as child of Parent
      expect(sheet.row(CHILD_1)[RELATION]).to eq "child of"
      expect(sheet.row(CHILD_1)[RELATED_SUBJECT]).to eq "Parent"

      # shows Child 2 as child of Parent
      expect(sheet.row(CHILD_2)[RELATION]).to eq "child of"
      expect(sheet.row(CHILD_2)[RELATED_SUBJECT]).to eq "Parent"

      # shows Child 2 as parent of Child 2's child
      expect(sheet.row(CHILD_2 + 1)[RELATION]).to eq "parent of"
      expect(sheet.row(CHILD_2 + 1)[RELATED_SUBJECT]).to eq "Child 2's child"

      # shows Child 2 as following Followed
      expect(sheet.row(CHILD_2 + 2)[RELATION]).to eq "Follows"
      expect(sheet.row(CHILD_2 + 2)[RELATED_SUBJECT]).to eq "Followed"

      # shows no relation information for Single
      expect(sheet.row(SINGLE).drop(7).compact).to eq []

      # shows Followed as preceding Child 2'
      expect(sheet.row(FOLLOWED)[RELATION]).to eq "Precedes"
      expect(sheet.row(FOLLOWED)[RELATION_DESCRIPTION]).to eq "description foobar"
      expect(sheet.row(FOLLOWED)[RELATED_SUBJECT]).to eq "Child 2"

      # exports the correct data (examples)
      expect(sheet.row(PARENT))
        .to eq [
          nil, parent.type.name, parent.id.to_s, parent.subject, parent.status.name, parent.assigned_to, parent.priority.name,
          nil, "parent of", nil, nil,
          child_1.type.name, child_1.id.to_s, child_1.subject, child_1.status.name, child_1.assigned_to, child_1.priority.name
        ] # lag nil as this is a parent-child relation not represented by an actual Relation record

      expect(sheet.row(SINGLE))
        .to eq [
          nil, single.type.name, single.id.to_s, single.subject, single.status.name, single.assigned_to, single.priority.name
        ]

      expect(sheet.row(FOLLOWED))
        .to eq [
          nil,
          followed.type.name, followed.id.to_s, followed.subject, followed.status.name, followed.assigned_to, followed.priority.name,
          nil, "Precedes", 0, relation.description,
          child_2.type.name, child_2.id.to_s, child_2.subject, child_2.status.name, child_2.assigned_to, child_2.priority.name
        ]
    end

    context "with someone who may not see related work packages" do
      let(:current_user) { create(:user) }

      it "exports no information without visibility" do
        expect(sheet.rows.length).to eq(2)
        expect(sheet.column(1).drop(2)).to be_empty
      end
    end
  end

  describe "with cost and time entries" do
    # Since this test has to work without the actual costs plugin we'll just add
    # a custom field called 'costs' to emulate it.

    let(:custom_field) do
      create(:float_wp_custom_field,
             name: "unit costs")
    end
    let(:custom_value) do
      create(:custom_value,
             custom_field:)
    end
    let(:type) do
      type = project.types.first
      type.custom_fields << custom_field
      type
    end
    let(:project) do
      create(:project,
             work_package_custom_fields: [custom_field])
    end
    let(:work_packages) do
      wps = create_list(:work_package, 4,
                        project:,
                        type:)
      wps[0].estimated_hours = 27.5
      wps[0].save!
      wps[1].send(custom_field.attribute_setter, 1)
      wps[1].save!
      wps[2].send(custom_field.attribute_setter, 99.99)
      wps[2].save!
      wps[3].send(custom_field.attribute_setter, 1000)
      wps[3].save!
      wps
    end
    let(:column_names) { ["subject", "status", "estimated_hours", custom_field.column_name] }

    before do
      allow(Setting)
        .to receive(:plugin_costs)
        .and_return("costs_currency" => "EUR", "costs_currency_format" => "%n %u")
    end

    it "exports successfully the work packages with a cost column" do
      expect(sheet.rows.size).to eq(4 + 1)

      cost_column = sheet.columns.last.to_a
      %w[1 99.99 1000].each do |value|
        expect(cost_column).to include(value)
      end
    end

    context "with german locale" do
      let(:current_user) { create(:admin, language: :de) }

      it "exports successfully the work packages with a cost column localized" do
        I18n.with_locale :de do
          sheet
        end

        expect(sheet.rows.size).to eq(4 + 1)
        cost_column = sheet.columns.last.to_a
        %w[1 99,99 1000].each do |value|
          expect(cost_column).to include(value)
        end
      end
    end

    it "includes estimated hours" do
      expect(sheet.rows.size).to eq(4 + 1)

      # Check row after header row
      hours = sheet.rows[1].values_at(2)
      expect(hours).to include("27.5h")
    end
  end

  context "with descriptions" do
    let(:options) { { show_descriptions: "true" } }

    let(:work_package) do
      create(:work_package,
             description: "some arbitrary description \n <p>with some html</p>",
             project:,
             type: project.types.first)
    end
    let(:work_packages) { [work_package] }
    let(:column_names) { %w[id] }

    it "includes the HTML sanitized description" do
      expect(sheet.rows.size).to eq(1 + 1)

      expect(sheet.rows[1][1])
        .to eql("some arbitrary description \n with some html")
    end
  end

  context "with underscore in subject" do
    let(:work_package) do
      create(:work_package,
             subject: "underscore_is included",
             project:,
             type: project.types.first)
    end
    let(:work_packages) { [work_package] }
    let(:column_names) { %w[id subject] }

    it "includes the underscore" do
      expect(sheet.rows.size).to eq(1 + 1)

      expect(sheet.rows[1][1])
        .to eql(work_package.subject)
    end
  end

  describe "empty result" do
    let(:work_packages) { [] }

    it "yields an empty XLS file" do
      expect(sheet.rows.size).to eq(1) # just the headers
    end
  end

  describe "with user time zone" do
    let(:zone) { +2 }
    let(:work_package) do
      create(:work_package,
             project:,
             type: project.types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[subject status updated_at] }

    let(:i18n_helper) do
      Class.new do
        include Redmine::I18n
      end
    end

    before do
      allow(current_user).to receive(:time_zone).and_return(zone)
    end

    it "adapts the datetime fields to the user time zone" do
      work_package.reload
      updated_at_cell = sheet.rows.last.to_a.last
      expect(updated_at_cell).to eq(i18n_helper.format_time(work_package.updated_at).to_s)
    end
  end

  describe "with derived estimated hours" do
    let(:work_package) do
      create(:work_package,
             project:,
             derived_estimated_hours: 15.0,
             type: project.types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[subject status updated_at estimated_hours] }

    it "adapts the datetime fields to the user time zone" do
      work_package.reload
      estimated_cell = sheet.rows.last.to_a.last
      expect(estimated_cell).to eq "· Σ 15h"
    end
  end

  describe "with estimated and remaining hours set to zero and their derived value set" do
    let(:work_package) do
      create(:work_package,
             project:,
             estimated_hours: 0.0,
             derived_estimated_hours: 15.0,
             remaining_hours: 0.0,
             derived_remaining_hours: 8,
             type: project.types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[subject status updated_at estimated_hours remaining_hours] }

    it "outputs both values" do
      work_package.reload
      estimated_cell, remaining_cell = sheet.rows.last.to_a.last(2)
      expect(estimated_cell).to eq "0h · Σ 15h"
      expect(remaining_cell).to eq "0h · Σ 8h"
    end
  end
end
