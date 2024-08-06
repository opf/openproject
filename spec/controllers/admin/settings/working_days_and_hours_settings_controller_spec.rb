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

RSpec.describe Admin::Settings::WorkingDaysAndHoursSettingsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  require_admin_and_render_template("working_days_and_hours_settings")

  describe "update" do
    let(:working_days) { [*"1".."7"] }
    let(:non_working_days_attributes) { {} }
    let(:hours_per_day) { 4 }
    let(:params) do
      { settings: { working_days:, non_working_days_attributes:, hours_per_day: } }
    end

    subject { patch "update", params: }

    it "succeeds" do
      subject

      expect(response).to redirect_to action: "show"
      expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
    end

    context "with non_working_days" do
      let(:non_working_days_attributes) do
        { "0" => { "name" => "Christmas Eve", "date" => "2022-12-24" } }
      end

      it "succeeds" do
        subject

        expect(response).to redirect_to action: "show"
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
      end

      it "creates the non_working_days" do
        expect { subject }.to change(NonWorkingDay, :count).by(1)
        expect(NonWorkingDay.first).to have_attributes(name: "Christmas Eve", date: Date.parse("2022-12-24"))
      end
    end

    context "when fails with a duplicate entry" do
      let(:nwd_to_delete) { create(:non_working_day, name: "NWD to delete") }
      let(:non_working_days_attributes) do
        {
          "0" => { "name" => "Christmas Eve", "date" => "2022-12-24" },
          "1" => { "name" => "Christmas Eve2", "date" => "2022-12-24" },
          "2" => { "id" => nwd_to_delete.id, "_destroy" => true }
        }
      end

      it "displays the error message" do
        subject

        expect(response).to render_template :show
        expect(flash[:error]).to eq "A non-working day already exists for 2022-12-24."
      end

      it "sets the @modified_non_working_days variable" do
        subject
        expect(assigns(:modified_non_working_days)).to contain_exactly(
          hash_including("name" => "Christmas Eve", "date" => "2022-12-24"),
          hash_including("name" => "Christmas Eve2", "date" => "2022-12-24"),
          hash_including(nwd_to_delete.as_json(only: %i[id name
                                                        date]).merge("_destroy" => true))
        )
      end

      it "does not destroys other records" do
        subject
        expect { nwd_to_delete.reload }.not_to raise_error
      end
    end
  end
end
