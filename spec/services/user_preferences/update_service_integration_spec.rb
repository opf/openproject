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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe UserPreferences::UpdateService, 'integration', type: :model do
  shared_let(:current_user) do
    create(:user).tap do |u|
      u.pref.save
    end
  end
  shared_let(:preferences) do
    create(:user_preference, user: current_user)
  end

  let(:instance) { described_class.new(user: current_user, model: preferences) }

  let(:attributes) { {} }
  let(:service_result) do
    instance
      .call(attributes)
  end

  let(:updated_pref) do
    service_result.result
  end

  describe 'notification_settings' do
    subject { updated_pref.notification_settings }

    context 'with a partial update' do
      let(:attributes) do
        {
          notification_settings: [
            {
              project_id: nil,
              watched: false,
              involved: true,
              work_package_commented: false,
              work_package_created: true,
              work_package_processed: true,
              work_package_prioritized: false,
              work_package_scheduled: false
            }
          ]
        }
      end

      it 'updates the existing one, removes the email one' do
        default_ian = current_user.notification_settings.first

        expect(default_ian.watched).to eq true
        expect(default_ian.mentioned).to eq true
        expect(default_ian.involved).to eq true
        expect(default_ian.work_package_commented).to eq true
        expect(default_ian.work_package_created).to eq true
        expect(default_ian.work_package_processed).to eq true
        expect(default_ian.work_package_prioritized).to eq true
        expect(default_ian.work_package_scheduled).to eq true

        expect(subject.count).to eq 1
        expect(subject.first.project_id).to eq nil
        expect(subject.first.mentioned).to eq false
        expect(subject.first.watched).to eq false
        expect(subject.first.involved).to eq true
        expect(subject.first.work_package_commented).to eq false
        expect(subject.first.work_package_created).to eq true
        expect(subject.first.work_package_processed).to eq true
        expect(subject.first.work_package_prioritized).to eq false
        expect(subject.first.work_package_scheduled).to eq false

        expect(subject.first).to eq(default_ian.reload)
        expect(current_user.notification_settings.count).to eq(1)
        expect { default_ian.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a full replacement' do
      let(:project) { create :project }
      let(:attributes) do
        {
          notification_settings: [
            { project_id: project.id, mentioned: true }
          ]
        }
      end

      it 'inserts the setting, removing the old one' do
        default = current_user.notification_settings.to_a
        expect(default.count).to eq 1

        expect(subject.count).to eq 1
        expect(subject.first.project_id).to eq project.id

        NotificationSetting.all_settings.each do |key|
          val = subject.first.send key
          expect(val).to eq(key == :mentioned)
        end

        expect(current_user.notification_settings.count).to eq(1)

        expect { default.first.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
