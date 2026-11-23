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

require "rails_helper"

RSpec.describe WorkPackages::Exports::PDF::ExportSettingsComponent, type: :component do
  subject(:component) { described_class.new(build_stubbed(:query)) }

  it "disables the Gantt format when its enterprise feature is unavailable", with_ee: [] do
    render_inline(component)

    expect(page).to have_field("pdf_export_type_gantt", type: "radio", disabled: true)
  end

  describe "preselected export type" do
    subject(:component) { described_class.new(query) }

    let(:query) { create(:query) }

    def save_setting(format, updated_at)
      ExportSetting.create!(query:, format:, settings: { format: }).update_columns(updated_at:)
    end

    it "is the table without saved settings" do
      render_inline(component)

      expect(page).to have_field("pdf_export_type_table", type: "radio", checked: true)
    end

    context "with saved settings", with_ee: %i[gantt_pdf_export] do
      before do
        save_setting("pdf_report", 2.days.ago)
        save_setting("pdf_gantt", 1.day.ago)
        save_setting("csv", 1.hour.ago)
      end

      it "is the type of the most recently saved PDF settings" do
        render_inline(component)

        expect(page).to have_field("pdf_export_type_gantt", type: "radio", checked: true)
        expect(page).to have_css("[data-pdf-export-type='gantt']:not(.d-none)")
      end
    end

    context "with saved Gantt settings without the enterprise feature", with_ee: [] do
      before { save_setting("pdf_gantt", 1.day.ago) }

      it "is the table" do
        render_inline(component)

        expect(page).to have_field("pdf_export_type_table", type: "radio", checked: true)
      end
    end
  end
end
