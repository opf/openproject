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

RSpec.describe NotificationSettings::Scopes::Applicable do
  describe ".applicable" do
    subject(:scope) { NotificationSetting.applicable(project) }

    let!(:user) do
      create(:user,
             notification_settings:)
    end
    let!(:project) do
      create(:project)
    end

    context "when only global settings exist" do
      let(:notification_settings) do
        [
          build(:notification_setting, project: nil)
        ]
      end

      it "returns the global settings" do
        expect(scope)
          .to match_array(notification_settings)
      end
    end

    context "when global and project settings exist" do
      let(:project_notification_settings) do
        [
          build(:notification_setting, project:)
        ]
      end
      let(:global_notification_settings) do
        [
          build(:notification_setting)
        ]
      end
      let(:notification_settings) { project_notification_settings + global_notification_settings }

      it "returns the project settings" do
        expect(scope)
          .to match_array(project_notification_settings)
      end
    end

    context "when global and project settings exist but for a different project" do
      let(:other_project) { create(:project) }
      let(:project_notification_settings) do
        [
          build(:notification_setting, project: other_project)
        ]
      end
      let(:global_notification_settings) do
        [
          build(:notification_setting)
        ]
      end
      let(:notification_settings) { project_notification_settings + global_notification_settings }

      it "returns the project settings" do
        expect(scope)
          .to match_array(global_notification_settings)
      end
    end
  end
end
