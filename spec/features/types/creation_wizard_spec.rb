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

RSpec.describe "Sub-type creation wizard", :js, with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }

  before { login_as(admin) }

  def start_wizard
    visit types_path

    # The type's group is collapsed by default, hiding its "Add sub-type" footer link.
    find("[role='button'][aria-expanded='false']", text: bug_type.name).click
    click_on I18n.t("types.index.add_subtype", name: bug_type.name)
  end

  def inherited_caption
    ActionController::Base.helpers.strip_tags(
      I18n.t("types.creation_wizard.fields.inherited_from_parent_html", parent: bug_type.name)
    )
  end

  def complete_details_step(name)
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    bug_type.children.find_by(name:).tap { |subtype| expect(subtype).to be_present }
  end

  it "guides the admin through creating a sub-type with defaults" do
    start_wizard

    # Step 1 - Details: the core settings are inherited from the parent and shown read-only.
    expect(page).to have_text(inherited_caption, count: 3)
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: true)
    expect(page).to have_field(Type.human_attribute_name(:is_in_roadmap), disabled: true)
    expect(page).to have_css(".colors-autocomplete .ng-select-disabled")

    subtype = complete_details_step("Critical")

    click_on I18n.t(:button_continue) # Form configuration -> Workflows
    click_on I18n.t(:button_continue) # -> Automations
    click_on I18n.t(:button_continue) # -> Projects
    click_on I18n.t(:button_continue) # -> PDF generation
    click_on I18n.t("types.creation_wizard.finish")

    expect(page).to have_current_path(types_path)
    expect(subtype.reload.parent).to eq(bug_type)
  end

  it "links the aspects a sub-type inherits from its parent on creation" do
    start_wizard
    subtype = complete_details_step("Critical")

    # Reuse mode is no longer chosen in the wizard: a new sub-type simply defaults
    # to Linked-to-parent for the aspects it inherits (see Type::ConfigurationLinkable).
    Type::ConfigurationLink::DEFAULT_PARENT_LINK_ASPECTS.each do |aspect|
      expect(subtype.source_for(aspect)).to eq(bug_type)
    end
  end
end
