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

RSpec.describe Backlogs::SprintReports::Widgets::EnterpriseBanner, type: :component do
  subject(:rendered_component) { render_inline(described_class.new) }

  current_user { create(:user) }

  context "without the sprint_report_pro_widgets entitlement" do
    it "upsells the widgets the report is missing" do
      expect(rendered_component).to have_test_selector("op-enterprise-banner", text: "Full sprint report")
      expect(rendered_component).to have_text("Add more charts, customize your report")
      expect(rendered_component).to have_text("Professional enterprise plan")
    end
  end

  context "with the sprint_report_pro_widgets entitlement", with_ee: %i[sprint_report_pro_widgets] do
    it "renders nothing at all, leaving no empty widget behind" do
      expect(rendered_component.to_html).to be_empty
    end
  end

  context "when enterprise banners are hidden by configuration" do
    before { allow(EnterpriseToken).to receive(:hide_banners?).and_return(true) }

    it "renders nothing at all, leaving no empty widget behind" do
      expect(rendered_component.to_html).to be_empty
    end
  end
end
