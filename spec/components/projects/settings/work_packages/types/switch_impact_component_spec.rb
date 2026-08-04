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

RSpec.describe Projects::Settings::WorkPackages::Types::SwitchImpactComponent,
               type: :component,
               with_flag: { type_variants: true } do
  subject(:render_component) { render_inline(described_class.new(impact:)) }

  shared_let(:story_points) { create(:integer_wp_custom_field, name: "Story points") }

  # let, not shared_let: Type#attribute_groups memoizes the parsed groups on the
  # instance, so a reused type would carry one example's configuration into the next.
  let(:epic) { create(:type, name: "Epic", custom_fields: [story_points]) }
  let(:design) { create(:type, name: "Design", parent: epic) }

  let(:project) { create(:project, types: [epic], work_package_custom_fields: [story_points]) }
  # nil when the target is the member already in use: deciding there is nothing to report
  # belongs to whoever renders this, not to the component.
  let(:impact) do
    Projects::Types::Switch::Impact.new(project:, source: epic, target:) unless target == epic
  end

  # The dialog opens on the member in use, so this is what a freshly opened
  # dialog renders — not a blank report.
  context "when the selection is still the member in use" do
    let(:target) { epic }

    it "invites the user to pick a different one" do
      render_component

      expect(page).to have_text("Select a different variant to see what will change")
    end

    it "renders no section headings, because there is nothing to report yet" do
      render_component

      expect(page).to have_no_text("Fields that will no longer be shown")
    end
  end

  context "with a target chosen" do
    let(:target) { design }

    shared_let(:role) { create(:project_role) }
    shared_let(:status) { create(:status, name: "New") }

    before do
      make_independent(design, Type::ConfigurationLink::FORM_CONFIGURATION)
      make_independent(design, Type::ConfigurationLink::WORKFLOWS)

      epic.attribute_groups = [["Details", ["assignee", "custom_field_#{story_points.id}"]]]
      epic.save!
      design.attribute_groups = [["Details", %w[priority]]]
      design.save!

      # Without a workflow the target allows no status at all, which would make
      # every status in use report as missing and render a fourth section.
      create(:workflow, type: design, role:, old_status: status, new_status: status)

      create(:work_package, project:, type: epic, status:)
        .update!(custom_field_values: { story_points.id => 5 })
    end

    it "states how many work packages the new configuration reaches" do
      render_component

      expect(page).to have_text("1 work package will use the new configuration")
    end

    it "heads the section that carries the risk" do
      render_component

      expect(page).to have_text("Fields that will no longer be shown")
    end

    # No JavaScript runs under render_inline, so a collapsed section's items are
    # still in the DOM and visible to Capybara.
    it "names each field that disappears" do
      render_component

      expect(page).to have_text("Assignee")
      expect(page).to have_text("Story points")
    end

    it "says how much data sits behind a custom field, and only behind a custom field" do
      render_component

      expect(page).to have_text("1 work package has a value", count: 1)
    end

    it "names the fields that become available" do
      render_component

      expect(page).to have_text("Fields that become available")
      expect(page).to have_text("Priority")
    end

    it "omits the statuses section, since no status in use is missing" do
      render_component

      expect(page).to have_no_text("Statuses missing from the new workflow")
    end
  end

  context "with a table on the source only" do
    let(:target) { design }

    shared_let(:query) { create(:query) }

    before do
      make_independent(design, Type::ConfigurationLink::FORM_CONFIGURATION)

      epic.attribute_groups = [["Details", %w[assignee]], ["Children", [:"query_#{query.id}"]]]
      epic.save!
      design.attribute_groups = [["Details", %w[assignee]]]
      design.save!
    end

    it "marks the table as a table rather than listing it as a field" do
      render_component

      expect(page).to have_text("Children")
      expect(page).to have_text("(table)")
    end
  end

  context "with a status no workflow of the target allows" do
    let(:target) { design }

    shared_let(:role) { create(:project_role) }
    shared_let(:allowed) { create(:status, name: "New") }
    shared_let(:orphan) { create(:status, name: "Blocked") }

    before do
      make_independent(design, Type::ConfigurationLink::FORM_CONFIGURATION)
      make_independent(design, Type::ConfigurationLink::WORKFLOWS)

      # Identical groups, so this example reports the status section alone.
      epic.attribute_groups = [["Details", %w[assignee]]]
      epic.save!
      design.attribute_groups = [["Details", %w[assignee]]]
      design.save!

      create(:workflow, type: design, role:, old_status: allowed, new_status: allowed)
      create_list(:work_package, 2, project:, type: epic, status: orphan)
    end

    it "reports the status and how many work packages hold it" do
      render_component

      expect(page).to have_text("Statuses missing from the new workflow")
      expect(page).to have_text("Blocked")
      expect(page).to have_text("2 work packages")
    end
  end

  context "when the two variants carry the same configuration" do
    let(:target) { design }

    shared_let(:role) { create(:project_role) }
    shared_let(:status) { create(:status, name: "New") }

    before do
      make_independent(design, Type::ConfigurationLink::WORKFLOWS)

      create(:workflow, type: design, role:, old_status: status, new_status: status)
      create(:work_package, project:, type: epic, status:)
    end

    # A bare count line with no sections reads as a report that failed to load.
    # This is the everyday case: a variant borrows its parent's form
    # configuration until somebody makes it independent.
    it "says so instead of rendering nothing under the count" do
      render_component

      expect(page).to have_text("1 work package will use the new configuration")
      expect(page).to have_text("No fields or statuses are affected")
    end
  end

  # A variant is created linked to its parent on every aspect, and the readers
  # resolve through the link once a pending change is saved, so a variant's own
  # configuration stays invisible until the link is severed.
  def make_independent(type, aspect)
    type.configuration_links.where(aspect:).destroy_all
  end
end
