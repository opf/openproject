#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe MailNotificationJob, type: :model do
  class StubNoticationJob < MailNotificationJob
    def initialize(recipient_id, author_id, mail_callback)
      super(recipient_id, author_id)
      @mail_callback = mail_callback
    end

    def notification_mail
      @mail_callback.call
    end
  end

  let(:recipient) { FactoryGirl.create(:user) }
  let(:author) { FactoryGirl.create(:user) }
  let(:mail) { double('a mail', deliver: nil) }
  let(:mail_callback) { -> { mail } }
  subject { StubNoticationJob.new(recipient.id, author.id, mail_callback) }

  describe 'the recipient should become the current user during mail creation' do
    let(:mail_callback) {
      -> {
        expect(User.current).to eql(recipient)
        mail
      }
    }

    it { subject.perform }
  end

  context 'for a known current user' do
    let(:current_user) { FactoryGirl.create(:user) }

    it 'resets to the previous current user after running' do
      User.current = current_user
      subject.perform
      expect(User.current).to eql(current_user)
    end
  end
end
