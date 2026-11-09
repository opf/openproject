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

RSpec.describe WorkPackage::Exports::Markdown, with_settings: { work_packages_identifier: "semantic" } do
  let(:cf_long_text) { create(:issue_custom_field, :text, name: "Notes", is_for_all: true) }
  let(:cf_bool) { create(:issue_custom_field, :boolean, name: "Flag", is_for_all: true) }
  let(:cf_code) { create(:issue_custom_field, :string, name: "Code", is_for_all: true) }
  let(:type) { create(:type_bug, custom_fields: [cf_long_text, cf_bool, cf_code]) }
  let(:project) { create(:project, identifier: "SE", types: [type]) }
  let(:other_project) { create(:project, types: [type]) }
  let(:hidden_project) { create(:project, types: [type]) }
  let(:priority) { create(:issue_priority, name: "Normal") }
  let(:query) do
    query = create(:query, project: nil)
    query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
    query.column_names = %i[id subject project_phase due_date]
    query.save!
    query
  end
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_project_phases],
                                             other_project => %i[view_work_packages] })
  end
  let(:work_package) do
    create(:work_package, project:, type:, priority:, assigned_to: user, estimated_hours: 10,
                          description: "Hello workPackageValue:subject",
                          custom_values: { cf_long_text.id => "**bold**", cf_bool.id => true, cf_code.id => "a|b\nc" })
  end
  let!(:child) { create(:work_package, project:, type:, parent: work_package, due_date: Date.new(2026, 11, 1)) }
  let!(:invisible_child) { create(:work_package, project: hidden_project, type:, parent: work_package) }
  let(:other_phase) do
    create(:project_phase, project: other_project, definition: create(:project_phase_definition, name: "Phase X"))
  end
  let!(:other_child) do
    create(:work_package, project: other_project, type:, parent: work_package,
                          project_phase_definition: other_phase.definition)
  end

  subject(:content) { described_class.new(work_package.reload).export!.content }

  before do
    login_as(user)
    variant = type.default_variant
    variant.attribute_groups = [
      ["Main", [:assignee, :"custom_field_#{cf_long_text.id}", :priority, :"custom_field_#{cf_bool.id}",
                :"custom_field_#{cf_code.id}"]],
      ["Estimates", [:estimated_time]],
      ["Embedded table for parent", [:"query_#{query.id}"]]
    ]
    variant.save!
  end

  it "renders the title, header block and groups in form order" do
    expect(content).to start_with(<<~MD)
      # Bug #{work_package.formatted_id} - #{work_package.subject}

      Project: #{project.name}
      Status: #{work_package.status.name}
      URL: http://#{Setting.host_name}/work_packages/#{work_package.display_id}

      ## Main

      | Attribute | Value |
      | --- | --- |
      | Assignee | #{user.name} |

      ### Notes

      **bold**

      | Attribute | Value |
      | --- | --- |
      | Priority | Normal |
      | Flag | Yes |
      | Code | a\\|b c |

    MD
  end

  it "renders the query group as a table with display ids and only visible work packages" do
    expect(content).to include("## Embedded table for parent\n\n| ID | Subject |")
    expect(content).to include("| #{child.reload.display_id} | #{child.subject} |")
    expect(content).not_to include(invisible_child.subject)
  end

  it "renders query dates as ISO dates" do
    expect(content).to include("| #{child.reload.display_id} | #{child.subject} |  | 2026-11-01 |")
  end

  it "blanks attributes the user may not view on a related work package" do
    expect(content).to include("| #{other_child.reload.display_id} | #{other_child.subject} |  |")
    expect(content).not_to include("Phase X")
  end

  it "renders an empty query group as a hint" do
    [child, invisible_child, other_child].each(&:destroy)
    expect(content).to include("## Embedded table for parent\n\n_No work packages_\n")
  end

  it "expands macros in the description and keeps raw markdown" do
    expect(content).to end_with("## Description\n\nHello #{work_package.subject}\n")
  end

  it "keeps task list markers unescaped when the description has macros" do
    work_package.update!(description: "workPackageValue:subject\n\n*   [ ] Open\n*   [x] Done")
    expect(content).to end_with("## Description\n\n#{work_package.subject}\n\n- [ ] Open\n- [x] Done\n")
  end

  it "renders wiki links in the description as Markdown links" do
    create(:wiki_page, wiki: create(:wiki, project:), title: "Wiki page")
    work_package.update!(description: "See [[Wiki page]]")
    expect(content).to end_with(
      "## Description\n\nSee [Wiki page](http://#{Setting.host_name}/projects/#{project.identifier}/wiki/wiki-page)\n"
    )
  end

  it "escapes pipes and newlines in table cells" do
    expect(content).to include("| Code | a\\|b c |")
  end

  it "escapes backslashes before pipes in table cells" do
    work_package.custom_field_values = { cf_code.id => 'a\b|c' }
    work_package.save!
    expect(content).to include('| Code | a\\\\b\|c |')
  end

  it "collapses bare carriage returns in table cells" do
    work_package.custom_field_values = { cf_code.id => "alpha\rbeta" }
    work_package.save!
    expect(content).to include("| Code | alpha beta |")
  end

  it "renders hours with their unit" do
    expect(content).to include("## Estimates\n\n| Attribute | Value |\n| --- | --- |\n| Work | 10h |\n")
  end

  it "translates the structural labels" do
    I18n.with_locale(:de) do
      expect(content).to include("\n#{WorkPackage.human_attribute_name(:project, locale: :de)}: ")
      expect(content).to include("| #{I18n.t(:label_attribute, locale: :de)} | ")
    end
  end

  it "omits the description section when blank" do
    work_package.update!(description: "")
    expect(content).not_to include("## Description")
  end

  context "with a query grouped by status" do
    let(:query) do
      query = create(:query, project: nil)
      query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
      query.column_names = %i[id subject status]
      query.group_by = "status"
      query.save!
      query
    end

    it "keeps the group-by column in the table" do
      expect(content).to include("| ID | Subject | Status |")
      expect(content).to include("| #{child.reload.display_id} | #{child.subject} | #{child.status.name} |")
    end
  end

  context "with a related work package whose parent is in a hidden project" do
    let(:hidden_parent) { create(:work_package, project: hidden_project, type:, subject: "CONFIDENTIAL parent") }
    let!(:related) { create(:work_package, project:, type:, parent: hidden_parent, subject: "Related row") }
    let(:query) do
      query = create(:query, project: nil)
      query.add_filter("subject", "~", [related.subject])
      query.column_names = %i[id subject parent]
      query.save!
      query
    end

    it "blanks the parent in a description macro" do
      related.update!(description: "Parent: workPackageValue:parent")
      expect(described_class.new(related.reload).export!.content).to end_with("## Description\n\nParent:\n")
    end

    it "blanks the parent cell" do
      expect(content).to include("| #{related.reload.display_id} | Related row |  |\n")
      expect(content).not_to include("CONFIDENTIAL parent")
    end
  end

  it "returns a text/markdown result" do
    expect(described_class.new(work_package.reload).export!)
      .to have_attributes(format: :md, mime_type: "text/markdown", title: "#{work_package.reload.display_id}.md")
  end
end
