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

describe AnnouncementMailer, type: :mailer do
  let(:announcement_subject) { 'Some subject' }
  let(:recipient) { build_stubbed(:user) }
  let(:announcement_body) { 'Some body text' }

  describe '#announce' do
    subject(:mail) do
      described_class.announce(recipient,
                               subject: announcement_subject,
                               body: announcement_body)
    end

    it "has a subject" do
      expect(mail.subject)
        .to eq announcement_subject
    end

    it 'includes the body' do
      expect(mail.body.encoded)
        .to include(announcement_body)
    end

    it "includes the subject in the body as well" do
      expect(mail.body.encoded)
        .to include announcement_subject
    end

    it 'sends to the recipient' do
      expect(mail.to)
        .to match_array [recipient.mail]
    end
  end
end
