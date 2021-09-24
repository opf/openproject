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

describe WorkPackageMailer, type: :mailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers

  let(:work_package) do
    FactoryBot.build_stubbed(:work_package,
                             project: project,
                             assigned_to: assignee)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:author) { FactoryBot.build_stubbed(:user) }
  let(:recipient) { FactoryBot.build_stubbed(:user) }
  let(:assignee) { FactoryBot.build_stubbed(:user) }
  let(:journal) do
    FactoryBot.build_stubbed(:work_package_journal,
                             journable: work_package,
                             user: author)
  end

  describe '#mentioned' do
    subject(:mail) { described_class.mentioned(recipient, journal) }

    it "has a subject" do
      expect(mail.subject)
        .to eql I18n.t(:'mail.mention.subject',
                       user_name: author.name,
                       id: work_package.id,
                       subject: work_package.subject)
    end

    it 'is sent to the recipient' do
      expect(mail.to)
        .to match_array([recipient.mail])
    end

    it 'has a project header' do
      expect(mail['X-OpenProject-Project'].value)
        .to eql project.identifier
    end

    it 'has a work package id header' do
      expect(mail['X-OpenProject-WorkPackage-Id'].value)
        .to eql work_package.id.to_s
    end

    it 'has a work package author header' do
      expect(mail['X-OpenProject-WorkPackage-Author'].value)
        .to eql work_package.author.login
    end

    it 'has a type header' do
      expect(mail['X-OpenProject-Type'].value)
        .to eql 'WorkPackage'
    end

    it 'has a message id header' do
      created_at = work_package.created_at.strftime('%Y%m%d%H%M%S')

      expect(mail['Message-ID'].value)
        .to eql "<openproject.work_package-#{recipient.id}-#{work_package.id}.#{created_at}@example.net>"
    end

    it 'has a references header' do
      created_at = work_package.created_at.strftime('%Y%m%d%H%M%S')

      expect(mail['References'].value)
        .to eql "<openproject.work_package-#{recipient.id}-#{work_package.id}.#{created_at}@example.net>"
    end

    it 'has a work package assignee header' do
      expect(mail['X-OpenProject-WorkPackage-Assignee'].value)
        .to eql work_package.assigned_to.login
    end
  end
end
