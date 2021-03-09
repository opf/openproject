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

describe UpdateUserEmailSettingsService, type: :model do
  let(:user_save_success) { true }
  let(:user_pref_save_success) { true }

  let(:user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u).to receive(:save).and_return(user_save_success)
      allow(u.pref).to receive(:save).and_return(user_pref_save_success)
    end
  end
  let(:service) { described_class.new(user) }

  describe '#call' do
    context 'saving is successful' do
      it 'returns true' do
        expect(service.call).to be_truthy
      end
    end

    context 'saving user is unsuccessful' do
      let(:user_save_success) { false }

      it 'returns false' do
        expect(service.call).to be_falsey
      end
    end

    context 'saving user preferences is unsuccessful' do
      let(:user_pref_save_success) { false }

      it 'returns false' do
        expect(service.call).to be_falsey
      end
    end

    it 'sets the mail_notification if provided' do
      expect(user).to receive(:mail_notification=).with(true)
      service.call(mail_notification: true)
    end

    it 'does not alter mail_notification if not provided' do
      expect(user).to_not receive(:mail_notification=)
      service.call
    end

    it 'sets self_notified if provided' do
      expect(user.pref).to receive(:self_notified=).with(true)
      service.call(self_notified: true)
    end

    it 'does not alter no_self_notified if not provided' do
      expect(user.pref).not_to receive(:[]=)
      service.call
    end

    it 'set the notified_project_ids on successful saving and mail_notifications is "selected"' do
      allow(user).to receive(:mail_notification).and_return 'selected'

      expect(user).to receive(:notified_project_ids=).with([1, 2, 3])

      service.call(notified_project_ids: [1, 2, 3])
    end
  end
end
