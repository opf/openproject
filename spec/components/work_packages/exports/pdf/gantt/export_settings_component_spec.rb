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

RSpec.describe WorkPackages::Exports::PDF::Gantt::ExportSettingsComponent, type: :component do
  subject(:component) { described_class.new(query) }

  let(:query) { create(:query) }

  it "offers to include work packages without dates, unchecked by default" do
    render_inline(component)

    expect(page).to have_field(I18n.t("export.dialog.pdf.gantt_include_without_dates.label"),
                               type: "checkbox", checked: false)
  end

  context "with the option saved" do
    before do
      query.export_settings_for("pdf_gantt").update!(settings: { gantt_include_without_dates: "true" })
    end

    it "restores it" do
      render_inline(component)

      expect(page).to have_field(I18n.t("export.dialog.pdf.gantt_include_without_dates.label"),
                                 type: "checkbox", checked: true)
    end
  end
end
