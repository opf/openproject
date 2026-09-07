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

RSpec.describe "Work package type projects tab", :skip_csrf, type: :rails_request,
                                                             with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type:, variant_name: "Firmware") }

  shared_let(:on_base) { create(:project, name: "OnBase", types: [type]) }
  shared_let(:on_hardware) { create(:project, name: "OnHardware", types: [hardware]) }
  shared_let(:on_firmware) { create(:project, name: "OnFirmware", types: [firmware]) }
  shared_let(:without_the_type) { create(:project, name: "Unrelated", types: []) }

  before { login_as admin }

  # The exact strings the filter form writes: FiltersFormController#buildFilterString quotes a
  # single value and brackets several, joining filters with "&". Its JSON output is opt-in and
  # off here, so a spec that posted JSON would be testing a shape the page never sends.
  def name_filter(term)
    %(name_and_identifier ~ "#{term}")
  end

  def variant_filter(*variants)
    values = variants.map { %("#{it.id}") }
    rendered = values.one? ? values.first : "[#{values.join(',')}]"

    "type_variant_id = #{rendered}"
  end

  def filters_for(*variants)
    variant_filter(*variants)
  end

  # Scoped to the table on purpose: a project name can appear elsewhere on the page, notably
  # echoed back in the search input, which would make a whole-body check agree with itself.
  def listed
    [on_base, on_hardware, on_firmware, without_the_type]
      .select { |project| page.has_css?("#project-table", text: project.name) }
  end

  describe "the variant a tab defaults to" do
    it "shows only its own projects inside a named variant" do
      get edit_type_projects_path(type_id: type.id, variant_id: hardware.id)

      expect(listed).to contain_exactly(on_hardware)
    end

    it "shows every variant's projects at type level" do
      get edit_type_projects_path(type_id: type.id)

      expect(listed).to contain_exactly(on_base, on_hardware, on_firmware)
    end

    it "never shows a project that does not use the type" do
      get edit_type_projects_path(type_id: type.id)

      expect(listed).not_to include(without_the_type)
    end
  end

  describe "the quick filter" do
    it "offers every variant of this type" do
      get edit_type_projects_path(type_id: type.id)

      expect(response.body).to include("Bug: Hardware").and include("Bug: Firmware")
    end

    it "narrows the table to the variants it names" do
      get edit_type_projects_path(type_id: type.id, filters: filters_for(firmware))

      expect(listed).to contain_exactly(on_firmware)
    end

    it "narrows to several at once" do
      get edit_type_projects_path(type_id: type.id, filters: filters_for(hardware, firmware))

      expect(listed).to contain_exactly(on_hardware, on_firmware)
    end

    it "widens a named variant's tab when asked for a sibling" do
      get edit_type_projects_path(type_id: type.id, variant_id: hardware.id, filters: filters_for(firmware))

      expect(listed).to contain_exactly(on_firmware)
    end

    it "ignores a variant belonging to another type" do
      other = create(:type, name: "Task")

      get edit_type_projects_path(type_id: type.id, filters: filters_for(other.default_variant))

      expect(listed).to contain_exactly(on_base, on_hardware, on_firmware)
    end

    it "ignores a malformed filter" do
      get edit_type_projects_path(type_id: type.id, filters: "not json")

      expect(listed).to contain_exactly(on_base, on_hardware, on_firmware)
    end
  end

  describe "the project name filter" do
    it "narrows the table to the projects whose name matches" do
      get edit_type_projects_path(type_id: type.id, filters: name_filter("OnHard"))

      expect(listed).to contain_exactly(on_hardware)
    end

    # Both controls write the one `filters` param, so they have to narrow together rather than
    # the last one written winning.
    it "narrows alongside the variant filter" do
      filters = "#{variant_filter(hardware, firmware)}&#{name_filter('OnFirm')}"

      get edit_type_projects_path(type_id: type.id, filters:)

      expect(listed).to contain_exactly(on_firmware)
    end

    it "still cannot reach a project that does not use the type" do
      get edit_type_projects_path(type_id: type.id, filters: name_filter("Unrelated"))

      expect(listed).to be_empty
    end

    it "keeps the term in the input so the search is visible after reload" do
      get edit_type_projects_path(type_id: type.id, filters: name_filter("OnHard"))

      expect(page).to have_css("input[name=name_and_identifier][value=OnHard]", visible: :all)
    end
  end

  # The filter form only binds its listener when live updates are on, and it then fetches this
  # action for turbo streams. Answering only HTML would leave typing doing nothing at all.
  describe "live updates as the filter changes" do
    it "answers a turbo stream request with the narrowed table" do
      get edit_type_projects_path(type_id: type.id, filters: name_filter("OnHard")),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("OnHardware")
      expect(response.body).not_to include("OnFirmware")
    end

    it "declares live updates on the filter form, so the input is listened to" do
      get edit_type_projects_path(type_id: type.id)

      expect(page).to have_css("[data-controller~='filter--filters-form']" \
                               "[data-filter--filters-form-turbo-stream-request-value='true']")
    end
  end

  describe "the empty table" do
    it "invites adding a project when nothing is filtered" do
      spare = create(:type_variant, type:, variant_name: "Spare")

      get edit_type_projects_path(type_id: type.id, variant_id: spare.id)

      expect(page).to have_css("#project-table", text: I18n.t("types.edit.projects.empty_state.description"))
    end

    # Inviting the admin to add a project reads as a lie right after they searched for one.
    it "says nothing matched when a filter is applied" do
      get edit_type_projects_path(type_id: type.id, filters: name_filter("nothing matches this"))

      expect(page).to have_css("#project-table", text: I18n.t("types.edit.projects.empty_state.no_results"))
      expect(page).to have_no_css("#project-table",
                                  text: I18n.t("types.edit.projects.empty_state.description"))
    end
  end

  describe "where the variant filter is offered" do
    it "offers it at type level" do
      get edit_type_projects_path(type_id: type.id)

      expect(page).to have_css("[data-test-selector='quick-filter-select-panel-button']")
    end

    it "leaves it out inside a variant" do
      get edit_type_projects_path(type_id: type.id, variant_id: hardware.id)

      expect(page).to have_no_css("[data-test-selector='quick-filter-select-panel-button']")
    end

    it "keeps the project name search inside a variant" do
      get edit_type_projects_path(type_id: type.id, variant_id: hardware.id)

      expect(page).to have_field("name_and_identifier", visible: :all)
    end
  end
end
