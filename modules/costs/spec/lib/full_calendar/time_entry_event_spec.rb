# frozen_string_literal: true

require "spec_helper"

# Regression guard for COMMS-837: the "My time tracking" workweek calendar must
# link each time-entry event to its work package by the display identifier, so
# semantic identifiers (e.g. "PROJ-42") route through /wp/<identifier> instead
# of the bare numeric id.
RSpec.describe FullCalendar::TimeEntryEvent do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:work_package) do
    create(:work_package, project:, type:, subject: "Fix the thing").tap do |wp|
      wp.update_columns(identifier: "PROJ-42", sequence_number: 42)
    end
  end
  shared_let(:time_entry) { create(:time_entry, entity: work_package) }

  subject(:json) { described_class.from_time_entry(time_entry).as_json }

  context "with semantic mode", with_settings: { work_packages_identifier: "semantic" } do
    it "links the work package by its semantic identifier" do
      expect(json["workPackageId"]).to eq("PROJ-42")
    end

    it "shows the semantic identifier in the event title" do
      expect(json["title"]).to eq("#{project.name}: PROJ-42 Fix the thing")
    end
  end

  context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
    it "links the work package by its numeric id" do
      expect(json["workPackageId"]).to eq(work_package.id.to_s)
    end

    it "shows the numeric id in the event title" do
      expect(json["title"]).to eq("#{project.name}: ##{work_package.id} Fix the thing")
    end
  end
end
