# frozen_string_literal: true

require "rails_helper"

# Specs for the Scrum Base-style "group by epic" view of the backlog inbox.
RSpec.describe Backlogs::InboxComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  shared_let(:epic) { create(:work_package, project:, subject: "Conference epic") }
  shared_let(:child_a) { create(:work_package, project:, parent: epic, subject: "Child A") }
  shared_let(:child_b) { create(:work_package, project:, parent: epic, subject: "Child B") }
  shared_let(:orphan) { create(:work_package, project:, subject: "No-parent item") }

  let(:work_packages) { WorkPackage.where(id: [child_a, child_b, orphan]).order(:id) }

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(
                    work_packages:,
                    project:,
                    group_by_epic:,
                    current_user: user
                  ))
  end

  context "when group_by_epic is false (default flat list)" do
    let(:group_by_epic) { false }

    it "does not render any epic group headers" do
      expect(rendered_component).to have_no_css(".op-backlog-epic-group")
    end
  end

  context "when group_by_epic is true" do
    let(:group_by_epic) { true }

    it "renders an epic group header for the parent", :aggregate_failures do
      rendered_component

      expect(page).to have_css(".op-backlog-epic-group", text: "Conference epic")
      expect(page).to have_css(".op-backlog-epic-group--count", text: "2")
    end

    it "renders a group for items without an epic" do
      expect(rendered_component).to have_css(".op-backlog-epic-group", text: "No epic")
    end
  end
end
