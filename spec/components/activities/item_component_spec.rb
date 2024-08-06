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

require "rails_helper"

RSpec.describe Activities::ItemComponent, type: :component do
  let(:event) do
    Activities::Event.new(
      event_title: "Event Title",
      event_description: "something",
      event_datetime: journal.created_at,
      event_path: "/project/123",
      project_id: project.id,
      project:,
      journal:
    )
  end
  let(:project) { build_stubbed(:project, name: "My project") }
  let(:journal) { build_stubbed(:work_package_journal) }

  it "renders the activity title" do
    render_inline(described_class.new(event:))

    expect(page).to have_css(".op-activity-list--item-title", text: "Event Title")
  end

  it 'adds "(Project: ...)" suffix after the activity title' do
    render_inline(described_class.new(event:))

    expect(page).to have_css(".op-activity-list--item-title", text: /Event Title\s+\(Project: My project\)/)
  end

  it "escapes HTML in the activity title and the project suffix" do
    event.event_title = "Hello <b>World</b>!"
    event.project.name = "Project <b>name</b> with HTML"
    render_inline(described_class.new(event:))

    expect(page).to have_css(".op-activity-list--item-title", text: "Hello <b>World</b>!")
    expect(page).to have_css(".op-activity-list--item-title", text: "Project: Project <b>name</b> with HTML)")
  end

  it "does not truncate the title" do
    event.event_title = "Hello, World!" * 20
    render_inline(described_class.new(event:))

    expect(page).to have_css(".op-activity-list--item-title", text: event.event_title)
  end

  it "removes line breaks and tabs from the title and replaces them with spaces" do
    event.event_title = "This \t should\n\rbe\n all\ncleaned"
    render_inline(described_class.new(event:))

    expect(page).to have_css(".op-activity-list--item-title", text: "This should be all cleaned")
  end

  context "for Project activities" do
    let(:journal) { build_stubbed(:project_journal) }

    it "does not add the project suffix" do
      component = described_class.new(event:)
      render_inline(component)

      expect(component.project_suffix).to be_nil
      expect(page).to have_css(".op-activity-list--item-title", text: /\A\s*Event Title\s*\z/)
    end
  end

  context "when :current_project is set" do
    it "does not display the project suffix for activities of the current project" do
      event.project.name = "My project"
      component = described_class.new(event:, current_project: project)
      render_inline(component)

      expect(component.project_suffix).to be_nil
      expect(page).to have_no_css(".op-activity-list--item-title", text: "(Project: My project)")
    end

    it 'adds "(Subproject: ...)" suffix for activities of subprojects of the current project' do
      parent_project = build_stubbed(:project)
      event.project.parent = parent_project
      event.project.name = "My subproject"
      render_inline(described_class.new(event:, current_project: parent_project))

      expect(page).to have_css(".op-activity-list--item-title", text: "(Subproject: My subproject)")
    end
  end

  context "when a journal change does not have a formatter associated" do
    it "does not display the change information" do
      event.event_description = ""
      allow(event.journal).to receive(:details).and_return(i_do_not_have_a_formatter_associated: ["old", "new"])
      render_inline(described_class.new(event:))

      expect(page).to have_no_css(".op-activity-list--item-detail")
    end
  end

  context "for TimeEntry activities" do
    let(:journal) { build_stubbed(:time_entry_journal) }
    let(:event) do
      Activities::Event.new(
        event_title: "Event Title",
        event_path: "/project/123",
        project_id: project.id,
        project:,
        journal:
      )
    end

    it "displays the title correctly" do
      component = described_class.new(event:)
      render_inline(component)
      expect(page).to have_css(".op-activity-list--item-title", text: /Event Title\s+\(Project: My project\)/)
    end
  end
end
