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

    it "renders the header rows and duplicates rows per relation" do
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
        .to eq [parent.id, parent.id, child_1.id, c2id, c2id, c2id, single.id, followed.id, child_2_child.id]
    end

    it "marks the parent-child relations" do
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
    end

    it "marks the follows and precedes relations" do
      # shows Child 2 as following Followed
      expect(sheet.row(CHILD_2 + 2)[RELATION]).to eq "Follows"
      expect(sheet.row(CHILD_2 + 2)[RELATED_SUBJECT]).to eq "Followed"

      # shows no relation information for Single
      expect(sheet.row(SINGLE).drop(7).compact).to eq []

      # shows Followed as preceding Child 2'
      expect(sheet.row(FOLLOWED)[RELATION]).to eq "Precedes"
      expect(sheet.row(FOLLOWED)[RELATION_DESCRIPTION]).to eq "description foobar"
      expect(sheet.row(FOLLOWED)[RELATED_SUBJECT]).to eq "Child 2"
    end

    it "exports the work package rows with their relation columns" do
      expect(sheet.row(PARENT))
        .to eq [
          nil, parent.type.name, parent.id, parent.subject, parent.status.name, parent.assigned_to, parent.priority.name,
          nil, "parent of", nil, nil,
          child_1.type.name, child_1.id, child_1.subject, child_1.status.name, child_1.assigned_to, child_1.priority.name
        ] # lag nil as this is a parent-child relation not represented by an actual Relation record

      expect(sheet.row(SINGLE))
        .to eq [
          nil, single.type.name, single.id, single.subject, single.status.name, single.assigned_to, single.priority.name
        ]

      expect(sheet.row(FOLLOWED))
        .to eq [
          nil,
          followed.type.name, followed.id, followed.subject, followed.status.name, followed.assigned_to, followed.priority.name,
          nil, "Precedes", 0, relation.description,
          child_2.type.name, child_2.id, child_2.subject, child_2.status.name, child_2.assigned_to, child_2.priority.name
        ]
    end

    it "applies the column formats to both work package column blocks" do
      expect(sheet.row(2).format(2).number_format).to eq("0")
      expect(sheet.row(2).format(12).number_format).to eq("0")
    end

    context "with descriptions as well" do
      let(:options) { { show_relations: "true", show_descriptions: "true" } }

      it "applies the column formats to both work package column blocks" do
        expect(sheet.row(2).format(2).number_format).to eq("0")
        expect(sheet.row(2).format(13).number_format).to eq("0")

        expect(sheet.row(2)[2]).to eq(parent.id)
        expect(sheet.row(2)[13]).to eq(child_1.id)
      end
    end

    context "with someone who may not see related work packages" do
      let(:current_user) { create(:user) }

      it "exports no information without visibility" do
        expect(sheet.rows.length).to eq(2)
        expect(sheet.column(1).drop(2)).to be_empty
      end
    end
  end

  describe "with cost and time entries", with_settings: { costs_currency: "EUR", costs_currency_format: "%n %u" } do
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
      type = project.enabled_types.first
      type.default_variant.custom_fields << custom_field

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

    it "exports successfully the work packages with a cost column" do
      expect(sheet.rows.size).to eq(4 + 1)

      cost_column = sheet.columns.last.to_a
      [1.0, 99.99, 1000.0].each do |value|
        expect(cost_column).to include(value)
      end

      cost_column_index = sheet.rows.first.to_a.index(custom_field.name)
      expect(sheet.row(1).format(cost_column_index).number_format).to eq("0.00")
    end

    it "includes work" do
      expect(sheet.rows.size).to eq(4 + 1)

      # Check row after header row
      hours = sheet.rows[1].values_at(2)
      expect(hours).to include(27.5)
    end

    context "with duration format being set to 'days and hours'", with_settings: { duration_format: "days_and_hours" } do
      it "includes work unformatted" do
        expect(sheet.rows.size).to eq(4 + 1)

        # Check row after header row
        hours = sheet.rows[1].values_at(2)
        expect(hours).to include(27.5)
      end
    end
  end

  context "with descriptions" do
    let(:options) { { show_descriptions: "true" } }

    let(:work_package) do
      create(:work_package,
             description: "some arbitrary description \n <p>with some html</p>",
             project:,
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }
    let(:column_names) { %w[id] }

    it "includes the HTML sanitized description" do
      expect(sheet.rows.size).to eq(1 + 1)

      expect(sheet.rows[1][1])
        .to eql("some arbitrary description \n with some html")
    end
  end

  context "with semantic work package identifiers",
          with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "XLSPROJ") }
    let(:work_package) do
      create(:work_package,
             project:,
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }
    let(:column_names) { %w[id subject] }

    it "exports the semantic identifier in the ID column" do
      expect(sheet.rows.size).to eq(1 + 1)

      expect(work_package.identifier).to match(/\AXLSPROJ-\d+\z/)
      expect(sheet.rows[1][0]).to eq work_package.identifier
    end
  end

  context "with underscore in subject" do
    let(:work_package) do
      create(:work_package,
             subject: "underscore_is included",
             project:,
             type: project.enabled_types.first)
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
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[subject status updated_at] }

    before do
      allow(current_user).to receive(:time_zone).and_return(zone)
    end

    it "adapts the datetime fields to the user time zone" do
      work_package.reload
      updated_at_cell = sheet.rows.last.to_a.last
      expected = work_package.updated_at.in_time_zone(zone)

      expect(updated_at_cell).to be_a(DateTime)
      expect(updated_at_cell.strftime("%Y-%m-%d %H:%M")).to eq(expected.strftime("%Y-%m-%d %H:%M"))
    end
  end

  describe "with typed columns" do
    let(:int_cf) { create(:integer_wp_custom_field, name: "Units") }
    let(:float_cf) { create(:float_wp_custom_field, name: "Weight") }
    let(:date_cf) { create(:date_wp_custom_field, name: "Reviewed on") }
    let(:custom_fields) { [int_cf, float_cf, date_cf] }

    let(:project) { create(:project, work_package_custom_fields: custom_fields) }

    let(:type) do
      type = project.enabled_types.first
      type.default_variant.custom_fields << custom_fields

      type
    end

    let(:work_package) do
      wp = create(:work_package,
                  project:,
                  type:,
                  start_date: Date.new(2026, 8, 24),
                  due_date: Date.new(2026, 9, 1))
      wp.send(int_cf.attribute_setter, 42)
      wp.send(float_cf.attribute_setter, 1234.5)
      wp.send(date_cf.attribute_setter, "2026-10-05")
      wp.save!
      wp
    end
    let(:work_packages) { [work_package] }

    let(:column_names) do
      %w[id start_date due_date created_at] + custom_fields.map(&:column_name)
    end

    let(:values) { sheet.rows[1].to_a }
    let(:number_formats) { column_names.each_index.map { |i| sheet.row(1).format(i).number_format } }

    it "writes dates and numbers as native values instead of strings" do
      expect(values[0]).to eq(work_package.id)
      expect(values[1]).to eq(Date.new(2026, 8, 24))
      expect(values[2]).to eq(Date.new(2026, 9, 1))
      expect(values[3]).to be_a(DateTime)
      expect(values[4]).to eq(42)
      expect(values[5]).to eq(1234.5)
      expect(values[6]).to eq(Date.new(2026, 10, 5))
    end

    it "sets a matching cell format on every typed column" do
      # With the date and time settings unset the formats follow the locale,
      # just like the rest of the product does through I18n.l.
      expect(number_formats)
        .to eq(["0", "MM/DD/YYYY", "MM/DD/YYYY", "MM/DD/YYYY HH:MM AM/PM", "0", "0.00", "MM/DD/YYYY"])
    end

    context "with a localised date format",
            with_settings: { date_format: "%d.%m.%Y", time_format: "%H:%M" } do
      it "translates the setting into an excel cell format" do
        expect(number_formats.values_at(1, 2, 6)).to all(eq("DD.MM.YYYY"))
        expect(number_formats[3]).to eq("DD.MM.YYYY HH:MM")
      end
    end

    context "when the typed values are empty" do
      let(:work_package) { create(:work_package, project:, type:) }

      it "leaves the cells blank" do
        expect(values[1]).to be_nil
        expect(values[4]).to be_nil
      end
    end
  end

  describe "with total work only" do
    let(:work_package) do
      create(:work_package,
             project:,
             derived_estimated_hours: 15.0,
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[estimated_hours remaining_hours done_ratio] }

    it "outputs its raw value in an additional 'Total work' column right after the 'Work' column" do
      headers_row, values_row = sheet.rows
      # why is there a nil at the end of the headers row?
      headers_row.compact!
      expect(headers_row.zip(values_row)).to eq [
        ["Work", nil],
        ["Total work", 15.0],
        ["Remaining work", nil],
        ["Total remaining work", nil],
        ["% Complete", nil],
        ["Total % complete", nil]
      ]
    end
  end

  describe "with work, total work, remaining work, total remaining work, % complete, and total % complete" do
    let(:work_package) do
      create(:work_package,
             project:,
             estimated_hours: 10.0,
             derived_estimated_hours: 15.0,
             remaining_hours: 5.0,
             derived_remaining_hours: 8.0,
             done_ratio: 50,
             derived_done_ratio: 75,
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[estimated_hours remaining_hours done_ratio] }

    it "outputs all raw values in distinct columns for own and total values" do
      headers_row, values_row = sheet.rows
      # why is there a nil at the end of the headers row?
      headers_row.compact!
      expect(headers_row.zip(values_row)).to eq [
        ["Work", 10.0],
        ["Total work", 15.0],
        ["Remaining work", 5.0],
        ["Total remaining work", 8.0],
        ["% Complete", 0.5],
        ["Total % complete", 0.75]
      ]
    end
  end

  describe "with work, remaining work, and % complete set to zero and their total values set" do
    let(:work_package) do
      create(:work_package,
             project:,
             estimated_hours: 0.0,
             derived_estimated_hours: 15.0,
             remaining_hours: 0.0,
             derived_remaining_hours: 8,
             done_ratio: 0,
             derived_done_ratio: 42,
             type: project.enabled_types.first)
    end
    let(:work_packages) { [work_package] }

    let(:column_names) { %w[estimated_hours remaining_hours done_ratio] }

    it "outputs raw values in distinct columns for own and total values" do
      headers_row, values_row = sheet.rows
      # why is there a nil at the end of the headers row?
      headers_row.compact!
      expect(headers_row.zip(values_row)).to eq [
        ["Work", 0.0],
        ["Total work", 15.0],
        ["Remaining work", 0.0],
        ["Total remaining work", 8.0],
        ["% Complete", 0.0],
        ["Total % complete", 0.42]
      ]
    end
  end
end
