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

RSpec.describe ProjectStatusHelper do
  describe "#project_status_css_class" do
    context "when status_code is nil" do
      it "returns '-not-set' css class" do
        expect(helper.project_status_css_class(nil)).to eq("-not-set")
      end
    end

    context "when status_code is set" do
      it "returns the css class", :aggregate_failures do
        expect(helper.project_status_css_class(:off_track)).to eq("-off-track")
        expect(helper.project_status_css_class("finished")).to eq("-finished")
      end
    end
  end

  describe "#project_status_name" do
    context "when status_code is nil" do
      it "returns 'not set' name" do
        expect(helper.project_status_name(nil)).to eq I18n.t("js.grid.widgets.project_status.not_set")
      end
    end

    context "when status_code is set" do
      it "returns the localized name", :aggregate_failures do
        expect(helper.project_status_name(:on_track)).to eq I18n.t("js.grid.widgets.project_status.on_track")
        expect(helper.project_status_name("discontinued")).to eq I18n.t("js.grid.widgets.project_status.discontinued")
      end
    end
  end
end
