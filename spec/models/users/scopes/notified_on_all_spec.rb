#-- encoding: UTF-8

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

describe Users::Scopes::NotifiedOnAll, type: :model do
  describe '.notified_on_all' do
    subject(:scope) { ::User.notified_on_all(project) }

    let!(:user) do
      FactoryBot.create(:user,
                        notification_settings: notification_settings)
    end
    let!(:project) do
      FactoryBot.create(:project)
    end

    context 'when user is notified about everything' do
      let(:notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: true),
          FactoryBot.build(:in_app_notification_setting, all: true)
        ]
      end

      it 'includes the user' do
        expect(scope)
          .to match_array([user])
      end

      context 'with in app notifications disabled' do
        let(:notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, all: true),
            FactoryBot.build(:in_app_notification_setting, all: false)
          ]
        end

        it 'includes the user' do
          expect(scope)
            .to match_array([user])
        end
      end

      context 'with mail notifications disabled' do
        let(:notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, all: false),
            FactoryBot.build(:in_app_notification_setting, all: true)
          ]
        end

        it 'includes the user' do
          expect(scope)
            .to match_array([user])
        end
      end

      context 'with all disabled' do
        let(:notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, all: false),
            FactoryBot.build(:in_app_notification_setting, all: false)
          ]
        end

        it 'is empty' do
          expect(scope)
            .to be_empty
        end
      end

      context 'with all disabled as a default but enabled in the project' do
        let(:notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, all: false),
            FactoryBot.build(:in_app_notification_setting, all: false),
            FactoryBot.build(:mail_notification_setting, project: project, all: true),
            FactoryBot.build(:in_app_notification_setting, project: project, all: true)
          ]
        end

        it 'includes the user' do
          expect(scope)
            .to match_array([user])
        end
      end

      context 'with all enabled as a default but disabled in the project' do
        let(:notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, all: true),
            FactoryBot.build(:in_app_notification_setting, all: true),
            FactoryBot.build(:mail_notification_setting, project: project, all: false),
            FactoryBot.build(:in_app_notification_setting, project: project, all: false)
          ]
        end

        it 'is empty' do
          expect(scope)
            .to be_empty
        end
      end
    end
  end
end
