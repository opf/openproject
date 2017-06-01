#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UpdateUserEmailSettingsService, type: :model do
  let(:user) { stub_model(User) }
  let(:service) { described_class.new(user) }

  describe '#call' do
    it 'returns true if saving is successful' do
      allow(user).to receive(:save).and_return(true)
      allow(user.pref).to receive(:save).and_return(true)

      expect(service.call).to be_truthy
    end

    it 'returns false if saving of user is unsuccessful' do
      allow(user).to receive(:save).and_return(false)
      allow(user.pref).to receive(:save).and_return(true)

      expect(service.call).to be_falsey
    end

    it 'returns false if saving of user preference is unsuccessful' do
      allow(user).to receive(:save).and_return(true)
      allow(user.pref).to receive(:save).and_return(false)

      expect(service.call).to be_falsey
    end

    it 'sets the mail_notification if provided' do
      expect(user).to receive(:mail_notification=).with(true)
      service.call(mail_notification: true)
    end

    it 'does not alter mail_notification if not provided' do
      expect(user).to_not receive(:mail_notification=)
      service.call()
    end

    it 'sets self_notified if provided' do
      expect(user.pref).to receive(:self_notified=).with(true)
      service.call(self_notified: true)
    end

    it 'does not alter no_self_notified if not provided' do
      expect(user.pref).not_to receive(:[]=)
      service.call()
    end

    it 'set the notified_project_ids on successful saving and mail_notifications is "selected"' do
      allow(user).to receive(:mail_notification).and_return 'selected'
      allow(user).to receive(:save).and_return true
      allow(user.pref).to receive(:save).and_return true

      expect(user).to receive(:notified_project_ids=).with([1,2,3])

      service.call(notified_project_ids: [1,2,3])
    end
  end
end
