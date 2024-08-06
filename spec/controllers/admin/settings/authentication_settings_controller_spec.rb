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

RSpec.describe Admin::Settings::AuthenticationSettingsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  require_admin_and_render_template("authentication_settings")

  describe "PATCH #update" do
    describe "registration_footer" do
      let(:old_settings) do
        {
          registration_footer: {
            "de" => "Old German registration footer",
            "en" => "Old English registration footer"
          }
        }
      end

      let(:new_settings) do
        {
          registration_footer: {
            "de" => "New German registration footer",
            "en" => "New English registration footer"
          }
        }
      end

      before do
        old_settings.each_key do |key|
          Setting[key] = old_settings[key]
        end
      end

      describe "when writable" do
        before do
          patch "update", params: { settings: new_settings }
        end

        it "is successful" do
          expect(response).to redirect_to(admin_settings_authentication_path)
        end

        it "changes the registration_footer" do
          expect(Setting.registration_footer).to eq new_settings[:registration_footer]
        end
      end

      describe "when non-writable (set via env var)" do
        before do
          allow(Setting).to receive(:registration_footer_writable?).and_return(false)
          patch "update", params: { settings: new_settings }
        end

        it "is successful" do
          expect(response).to redirect_to(admin_settings_authentication_path)
        end

        it "does not change the registration_footer" do
          expect(Setting.registration_footer).to eq old_settings[:registration_footer]
        end
      end
    end
  end
end
