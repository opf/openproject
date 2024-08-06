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

RSpec.describe BacklogsSettingsController do
  current_user { build_stubbed(:admin) }

  describe "GET show" do
    it "performs that request" do
      get :show
      expect(response).to be_successful
      expect(response).to render_template :show
    end

    context "as regular user" do
      current_user { build_stubbed(:user) }

      it "fails" do
        get :show
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "PUT update" do
    subject do
      put :update,
          params: {
            settings: {
              task_type:,
              story_types:
            }
          }
    end

    context "with invalid settings (Regression test #35157)" do
      let(:task_type) { "1234" }
      let(:story_types) { ["1234"] }

      it "does not update the settings" do
        expect(Setting)
          .not_to(receive(:[]=))
          .with("plugin_openproject_backlogs", any_args)

        subject

        expect(response).to redirect_to action: :show
        expect(flash[:error]).to include I18n.t(:error_backlogs_task_cannot_be_story)
      end
    end

    context "with valid settings" do
      let(:task_type) { "1234" }
      let(:story_types) { ["5555"] }

      it "does update the settings" do
        expect(Setting)
          .to(receive(:[]=))
          .with("plugin_openproject_backlogs", { story_types: ["5555"], task_type: "1234" })

        subject

        expect(response).to redirect_to action: :show
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
        expect(flash[:error]).to be_nil
      end

      context "with a non-admin" do
        current_user { build_stubbed(:user) }

        it "does not update the settings" do
          expect(Setting)
            .not_to(receive(:[]=))
            .with("plugin_openproject_backlogs", any_args)

          subject

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end
  end
end
