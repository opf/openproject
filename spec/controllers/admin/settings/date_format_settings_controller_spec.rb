# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Admin::Settings::DateFormatSettingsController do
  shared_let(:user) { create(:admin) }
  current_user { user }

  require_admin_and_render_template("date_format_settings")

  describe "PATCH #update" do
    subject { patch "update", params: }

    let(:start_of_week) { 1 }
    let(:first_week_of_year) { 1 }
    let(:date_format) { Settings::Definition[:date_format].allowed.first }
    let(:time_format) { Settings::Definition[:time_format].allowed.first }
    let(:base_settings) do
      { start_of_week:, first_week_of_year:, date_format:, time_format: }
    end
    let(:params) { { settings: } }

    shared_examples "invalid combination of start_of_week and first_week_of_year" do |missing_param:|
      provided_param = (%i[start_of_week first_week_of_year] - [missing_param]).first

      context "when setting only #{provided_param} but not #{missing_param}" do
        let(:settings) { base_settings.except(missing_param) }

        it "redirects and sets the flash error" do
          subject

          expect(response).to redirect_to action: :show
          expect(flash[:error])
            .to eq(I18n.t("settings.date_format.first_date_of_week_and_year_set",
                          first_week_setting_name: I18n.t(:setting_first_week_of_year),
                          day_of_week_setting_name: I18n.t(:setting_start_of_week)))
        end
      end
    end

    include_examples "invalid combination of start_of_week and first_week_of_year", missing_param: :first_week_of_year
    include_examples "invalid combination of start_of_week and first_week_of_year", missing_param: :start_of_week
  end
end
