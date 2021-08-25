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

describe ::API::V3::UserPreferences::UserPreferenceRepresenter,
         'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:preference) { FactoryBot.build(:user_preference) }
  let(:notification_setting) { FactoryBot.build(:notification_setting) }
  let(:user) { FactoryBot.build_stubbed(:user, preference: preference) }
  let(:representer) { described_class.new(preference, current_user: user) }

  before do
    allow(preference).to receive(:user).and_return(user)
    allow(preference).to receive(:notification_settings).and_return([notification_setting])
  end

  subject(:generated) { representer.to_json }

  it { is_expected.to include_json('UserPreferences'.to_json).at_path('_type') }
  it { is_expected.to have_json_path('hideMail') }
  it { is_expected.to have_json_path('timeZone') }
  it { is_expected.to have_json_path('commentSortDescending') }
  it { is_expected.to have_json_path('warnOnLeavingUnsaved') }
  it { is_expected.to have_json_path('autoHidePopups') }

  describe 'timeZone' do
    context 'no time zone set' do
      let(:preference) { FactoryBot.build(:user_preference, time_zone: '') }

      it 'shows the timeZone as nil' do
        is_expected.to be_json_eql(nil.to_json).at_path('timeZone')
      end
    end

    context 'short timezone set' do
      let(:preference) { FactoryBot.build(:user_preference, time_zone: 'Berlin') }

      it 'shows the canonical time zone' do
        is_expected.to be_json_eql('Europe/Berlin'.to_json).at_path('timeZone')
      end
    end

    context 'canonical timezone set' do
      let(:preference) { FactoryBot.build(:user_preference, time_zone: 'Europe/Paris') }

      it 'shows the canonical time zone' do
        is_expected.to be_json_eql('Europe/Paris'.to_json).at_path('timeZone')
      end
    end
  end

  describe 'notification_settings' do
    it 'renders them as a nested array' do
      is_expected.to have_json_type(Array).at_path('notifications')
      is_expected.to be_json_eql(notification_setting.channel.to_json).at_path('notifications/0/channel')
      is_expected.to be_json_eql(nil.to_json).at_path('notifications/0/_links/project/href')
      is_expected.to be_json_eql(notification_setting.watched.to_json).at_path('notifications/0/watched')
      is_expected.to be_json_eql(notification_setting.involved.to_json).at_path('notifications/0/involved')
      is_expected.to be_json_eql(notification_setting.mentioned.to_json).at_path('notifications/0/mentioned')
      is_expected.to be_json_eql(notification_setting.all.to_json).at_path('notifications/0/all')
    end
  end

  describe '_links' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.user_preferences(user.id) }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'user' }
      let(:title) { user.name }
      let(:href) { api_v3_paths.user(user.id) }
    end

    describe 'immediate update' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'updateImmediately' }
        let(:href) { api_v3_paths.user_preferences(user.id) }
      end

      it 'is a patch link' do
        is_expected.to be_json_eql('patch'.to_json).at_path('_links/updateImmediately/method')
      end
    end
  end
end
