#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe NotificationSettings::Scopes::Applicable, type: :model do
  describe '.applicable' do
    subject(:scope) { ::NotificationSetting.applicable(project) }

    let!(:user) do
      FactoryBot.create(:user,
                        notification_settings: notification_settings)
    end
    let!(:project) do
      FactoryBot.create(:project)
    end

    context 'when only global settings exist' do
      let(:notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, project: nil),
          FactoryBot.build(:in_app_notification_setting, project: nil)
        ]
      end

      it 'returns the global settings' do
        expect(scope)
          .to match_array(notification_settings)
      end
    end

    context 'when global and project settings exist' do
      let(:project_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, project: project),
          FactoryBot.build(:in_app_notification_setting, project: project)
        ]
      end
      let(:global_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting),
          FactoryBot.build(:in_app_notification_setting)
        ]
      end
      let(:notification_settings) { project_notification_settings + global_notification_settings }

      it 'returns the project settings' do
        expect(scope)
          .to match_array(project_notification_settings)
      end
    end

    context 'when global and project settings exist but for a different project' do
      let(:other_project) { FactoryBot.create(:project) }
      let(:project_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, project: other_project),
          FactoryBot.build(:in_app_notification_setting, project: other_project)
        ]
      end
      let(:global_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting),
          FactoryBot.build(:in_app_notification_setting)
        ]
      end
      let(:notification_settings) { project_notification_settings + global_notification_settings }

      it 'returns the project settings' do
        expect(scope)
          .to match_array(global_notification_settings)
      end
    end
  end
end
