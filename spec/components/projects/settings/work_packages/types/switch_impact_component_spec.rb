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
  include Rails.application.routes.url_helpers

  subject(:render_component) { render_inline(described_class.new(impact:)) }

  shared_let(:story_points) { create(:integer_wp_custom_field, name: "Story points") }

  # let, not shared_let: Type#attribute_groups memoizes the parsed groups on the
  # instance, so a reused type would carry one example's configuration into the next.
  let(:epic) { create(:type, name: "Epic", custom_fields: [story_points]) }
  # A type owns a base variant holding the configuration it uses by default; a named variant is
  # an additional one. Both sides of the diff are variants, never the type.
  let(:epic_base) { epic.default_variant }
  let(:design) { create(:type_variant, type: epic, variant_name: "Design") }

  let(:project) { create(:project, types: [epic], work_package_custom_fields: [story_points]) }
  # nil when the target is the member already in use: deciding there is nothing to report
  # belongs to whoever renders this, not to the component.
  let(:impact) do
    Projects::Types::Switch::Impact.new(project:, source: epic_base, target:) unless target == epic_base
  end

  # The dialog opens on the member in use, and the field above already asks for a
  # different one, so a freshly opened dialog reports nothing rather than saying so.
  context "when the selection is still the member in use" do
    let(:target) { epic_base }

    it "renders nothing at all" do
      render_component

      expect(page).to have_no_text(/\S/)
    end
  end

  context "with a target chosen" do
    let(:target) { design }

    shared_let(:role) { create(:project_role) }
    shared_let(:status) { create(:status, name: "New") }

    before do
      epic_base.attribute_groups = [["Details", ["assignee", "custom_field_#{story_points.id}"]]]
      epic_base.save!
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

      expect(page).to have_no_text("Work packages that get stuck")
    end

    # Every counter answers "which ones?". A new tab because following a link in place would
    # navigate away from the dialog and discard the variant still being decided on.
    it "links the count to this project's work packages of that type, in a new tab" do
      render_component

      link = page.find_link("1 work package will use the new configuration")

      expect(link[:target]).to eq("_blank")
      expect(link[:href]).to start_with(project_work_packages_path(project))
      expect(CGI.unescape(link[:href])).to include(%({"n":"type","o":"=","v":["#{epic.id}"]}))
    end

    # Filtered rather than merely columned, so the list cannot disagree with the count.
    it "links a hidden custom field's value count to the work packages holding one" do
      render_component

      link = page.find_link("1 work package has a value")
      query = CGI.unescape(link[:href])

      expect(query).to include(%({"n":"type","o":"=","v":["#{epic.id}"]}))
      expect(query).to include(%({"n":"customField#{story_points.id}","o":"*","v":[]}))
      expect(query).to include(%("customField#{story_points.id}"))
    end
  end

  context "with a table on the source only" do
    let(:target) { design }

    shared_let(:query) { create(:query) }

    before do
      epic_base.attribute_groups = [["Details", %w[assignee]], ["Children", [:"query_#{query.id}"]]]
      epic_base.save!
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
      # Divergent groups too, so the report carries all three sections and their
      # order can be told apart.
      epic_base.attribute_groups = [["Details", %w[assignee]]]
      epic_base.save!
      design.attribute_groups = [["Details", %w[priority]]]
      design.save!

      create(:workflow, type: design, role:, old_status: allowed, new_status: allowed)
      create_list(:work_package, 2, project:, type: epic, status: orphan)
    end

    it "reports the status and how many work packages hold it" do
      render_component

      expect(page).to have_text("Work packages that get stuck")
      expect(page).to have_text("Blocked")
      expect(page).to have_text("2 work packages")
    end

    it "names the consequence rather than the mechanism behind it" do
      render_component

      expect(page).to have_text("nobody will be able to move these work packages on")
    end

    it "links a stuck status to the work packages holding it" do
      render_component

      query = CGI.unescape(page.find_link("2 work packages")[:href])

      expect(query).to include(%({"n":"type","o":"=","v":["#{epic.id}"]}))
      expect(query).to include(%({"n":"status","o":"=","v":["#{orphan.id}"]}))
    end

    # This is the only section whose consequence outlives the dialog, so it leads.
    # That it also renders expanded needs a browser, and is covered by the feature spec.
    it "puts the statuses ahead of the field sections" do
      render_component

      rendered = page.text
      expect(rendered.index("Work packages that get stuck")).to be < rendered.index("Fields that")
    end
  end

  context "when the two variants carry the same configuration" do
    let(:target) { design }

    shared_let(:role) { create(:project_role) }
    shared_let(:status) { create(:status, name: "New") }

    before do
      # Identical groups on both sides. A variant owns its configuration from creation, so
      # matching them is deliberate rather than the default it used to be.
      epic_base.attribute_groups = [["Details", %w[assignee]]]
      epic_base.save!
      design.attribute_groups = [["Details", %w[assignee]]]
      design.save!

      create(:workflow, type: design, role:, old_status: status, new_status: status)
      create(:work_package, project:, type: epic, status:)
    end

    # A bare count line with no sections reads as a report that failed to load.
    it "says so instead of rendering nothing under the count" do
      render_component

      expect(page).to have_text("1 work package will use the new configuration")
      expect(page).to have_text("No fields or statuses are affected")
    end
  end

  context "with an impact spanning several projects supplied with work packages" do
    shared_let(:role) { create(:project_role) }
    shared_let(:status) { create(:status, name: "New") }

    let(:one) { create(:project, types: [epic], work_package_custom_fields: [story_points]) }
    let(:two) { create(:project, types: [epic], work_package_custom_fields: [story_points]) }
    let(:impact) do
      Projects::Types::Switch::Impact.new(source: epic_base, target: design,
                                          work_packages: WorkPackage.where(type_id: epic.id))
    end

    before do
      epic_base.attribute_groups = [["Details", ["assignee", "custom_field_#{story_points.id}"]]]
      epic_base.save!
      design.attribute_groups = [["Details", %w[priority]]]
      design.save!
      create(:workflow, type: design, role:, old_status: status, new_status: status)

      create(:work_package, project: one, type: epic, status:)
      create(:work_package, project: two, type: epic, status:)
    end

    it "links the count to the global list, filtered to exactly the affected projects" do
      render_component

      link = page.find_link("2 work packages will use the new configuration")
      query = CGI.unescape(link[:href])

      expect(link[:href]).to start_with(work_packages_path)
      expect(link[:href]).not_to start_with(project_work_packages_path(one))
      expect(query).to include(%({"n":"project_id","o":"=","v":["#{one.id}","#{two.id}"]}))
      expect(query).to include(%({"n":"type","o":"=","v":["#{epic.id}"]}))
    end
  end
end
