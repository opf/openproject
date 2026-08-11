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

RSpec.describe WorkPackages::Admin::Settings::TargetVersionsSectionComponent, type: :component do
  subject(:component) { described_class.new(state: :action_required) }

  context "when the setting is writable" do
    before do
      allow(Settings::Definition[:work_package_multiple_versions]).to receive(:writable?).and_return(true)
    end

    it "renders the enable button" do
      render_inline(component)

      expect(page).to have_link("Enable multiple values")
    end

    it "shows the manual conversion hint" do
      render_inline(component)

      expect(page).to have_text(
        "You can choose to manually run the conversion to enable multiple values before this automatic migration happens."
      )
    end
  end

  context "when the setting is not writable" do
    before do
      allow(Settings::Definition[:work_package_multiple_versions]).to receive(:writable?).and_return(false)
    end

    it "does not render the enable button" do
      render_inline(component)

      expect(page).to have_no_link("Enable multiple values")
    end

    it "shows the not writable explanation instead of the manual conversion hint" do
      render_inline(component)

      expect(page).to have_text(
        "These settings are configured via environment variables. " \
        "If you would like to manually run the conversion to enable multiple values before the automatic migration, " \
        "update your configuration.yml file."
      )
      expect(page).to have_no_text(
        "You can choose to manually run the conversion to enable multiple values before this automatic migration happens."
      )
    end
  end

  context "when the conversion has completed" do
    subject(:component) { described_class.new(state: :completed) }

    it "nests the documentation link inside the row text rather than beside it" do
      render_inline(component)

      expect(page).to have_css("span a[href]", text: "our documentation")
    end
  end
end
