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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe DigestMailer, type: :mailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include Redmine::I18n

  let(:recipient) do
    build_stubbed(:user).tap do |u|
      allow(User)
        .to receive(:find)
              .with(u.id)
              .and_return(u)
    end
  end
  let(:project1) { build_stubbed(:project) }

  let(:work_package) do
    build_stubbed(:work_package,
                             type: build_stubbed(:type))
  end
  let(:journal) do
    build_stubbed(:work_package_journal,
                             notes: 'Some notes').tap do |j|
      allow(j)
        .to receive(:details)
              .and_return({ "subject" => ["old subject", "new subject"] })
    end
  end
  let(:notifications) do
    [build_stubbed(:notification,
                              resource: work_package,
                              reason: :commented,
                              journal: journal,
                              project: project1)].tap do |notifications|
      allow(Notification)
        .to receive(:where)
              .and_return(notifications)

      allow(notifications)
        .to receive(:includes)
              .and_return(notifications)
    end
  end

  describe '#work_packages' do
    subject(:mail) { described_class.work_packages(recipient.id, notifications.map(&:id)) }

    let(:mail_body) { mail.body.parts.detect { |part| part['Content-Type'].value == 'text/html' }.body.to_s }

    it 'notes the day and the number of notifications in the subject' do
      expect(mail.subject)
        .to eql "OpenProject - 1 unread notification"
    end

    it 'sends to the recipient' do
      expect(mail.to)
        .to match_array [recipient.mail]
    end

    it 'sets the expected message_id header' do
      allow(Time)
        .to receive(:current)
              .and_return(Time.current)

      expect(mail.message_id)
        .to eql "op.digest.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@example.net"
    end

    it 'sets the expected openproject headers' do
      expect(mail['X-OpenProject-User']&.value)
        .to eql recipient.name
    end

    it 'includes the notifications grouped by work package' do
      time_stamp = journal.created_at.strftime('%m/%d/%Y, %I:%M %p')
      expect(mail_body)
        .to have_text("Hey #{recipient.firstname}!")

      expected_notification_subject = "#{work_package.type.name.upcase} #{work_package.subject}"
      expect(mail_body)
        .to have_text(expected_notification_subject, normalize_ws: true)

      expected_notification_header = "#{work_package.status.name} ##{work_package.id} - #{work_package.project}"
      expect(mail_body)
        .to have_text(expected_notification_header, normalize_ws: true)

      expected_text = "#{journal.initial? ? 'Created' : 'Updated'} at #{time_stamp} by #{recipient.name}"
      expect(mail_body)
        .to have_text(expected_text, normalize_ws: true)
    end

    context 'with only a deleted work package for the digest' do
      let(:work_package) { nil }

      it `is a NullMail which isn't sent` do
        expect(mail.body)
          .to eql ''

        expect(mail.header)
          .to eql({})
      end
    end
  end
end
