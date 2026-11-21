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

RSpec.describe "Embedded query group editor across a main table save", :js do
  let(:user) { create(:admin) }
  let(:type) { create(:type_with_relation_query_group) }
  let(:project) { create(:project, types: [type]) }
  let!(:parent) { create(:work_package, project:, type:, subject: "Embedded parent") }
  let!(:child) { create(:work_package, project:, type:, parent:, subject: "Embedded child") }
  let!(:other) { create(:work_package, project:, type:, subject: "Main table other") }

  let(:list_query) do
    create(:query, project:, user:, column_names: %w[id subject]).tap do |query|
      query.add_filter("id", "=", [parent.id.to_s, other.id.to_s])
      query.save!
    end
  end

  let(:split_view) { Pages::PrimerizedSplitWorkPackage.new(parent, project) }
  let(:list) { Pages::WorkPackagesTable.new(project) }
  let(:wp_table) do
    Pages::EmbeddedWorkPackagesTable.new(find("wp-single-view .work-packages-embedded-view--container"))
  end

  before do
    parent.status.update_attribute :is_default, true
    parent.priority.update_attribute :is_default, true

    login_as user
    split_view.visit_query(list_query)
    split_view.ensure_page_loaded
    list.expect_work_package_listed(parent, other)
    wp_table.expect_work_package_listed(child)
    wait_for_network_idle
  end

  it "keeps the embedded subject editor active when a main table save finishes" do
    hold_requests("/api/v3/queries/#{list_query.id}") do |held|
      main_subject = list.edit_field(other, :subject)
      main_subject.activate!
      main_subject.set_value "Main table saved"
      main_subject.submit_by_enter
      list.expect_toast(message: "Successful update.")
      reload = held.pop(timeout: 10)
      expect(reload).not_to be_nil

      embedded_subject = wp_table.edit_field(child, :subject)
      embedded_subject.display_element.click
      embedded_input = "##{embedded_subject.input_element[:id]}"
      expect(page).to have_focus_on(embedded_input)
      page.send_keys :end, " draft"

      reload.continue
      wait_for_network_idle

      expect(page).to have_focus_on(embedded_input)
      page.send_keys " more", :enter
      wp_table.expect_toast(message: "Successful update.")
      expect(wp_table.table_container).to have_text "Embedded child draft more"
    end
  end

  it "keeps the main table subject editor active when the main table reloads" do
    hold_requests("/api/v3/queries/#{list_query.id}") do |held|
      other_subject = list.edit_field(other, :subject)
      other_subject.activate!
      other_subject.set_value "Main table saved"
      other_subject.submit_by_enter
      list.expect_toast(message: "Successful update.")
      reload = held.pop(timeout: 10)
      expect(reload).not_to be_nil

      parent_subject = list.edit_field(parent, :subject)
      parent_subject.display_element.click
      parent_input = "##{parent_subject.input_element[:id]}"
      expect(page).to have_focus_on(parent_input)
      page.send_keys :end, " draft"

      reload.continue
      wait_for_network_idle

      expect(page).to have_focus_on(parent_input)
      page.send_keys " more", :enter
      expect(list.table_container).to have_text "Embedded parent draft more"
    end
  end
end
