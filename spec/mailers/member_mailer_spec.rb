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

describe MemberMailer, type: :mailer do
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:member) do
    FactoryBot.build_stubbed(:member,
                             principal: principal,
                             project: project,
                             roles: roles)
  end
  let(:principal) { FactoryBot.build_stubbed(:user) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:roles) { [FactoryBot.build_stubbed(:role), FactoryBot.build_stubbed(:role)] }

  shared_examples_for 'has a subject' do |key|
    it "has a subject" do
      if project
        expect(subject.subject)
          .to eql I18n.t(key, project: project.name)
      else
        expect(subject.subject)
          .to eql I18n.t(key)
      end
    end
  end

  shared_examples_for 'fails for a group' do
    let(:principal) { FactoryBot.build_stubbed(:group) }

    it 'raises an argument error' do
      # Calling .to in order to have the mail rendered
      expect { subject.to }
        .to raise_error ArgumentError
    end
  end

  shared_examples_for "sends a mail to the member's principal" do
    let(:principal) { FactoryBot.build_stubbed(:group) }

    it 'raises an argument error' do
      # Calling .to in order to have the mail rendered
      expect { subject.to }
        .to raise_error ArgumentError
    end
  end

  shared_examples_for 'sets the expected message_id header' do
    it 'sets the expected message_id header' do
      expect(subject['Message-ID'].value)
        .to eql "<openproject.member-#{current_user.id}-#{member.id}.#{member.created_at.strftime('%Y%m%d%H%M%S')}@example.net>"
    end
  end

  shared_examples_for 'sets the expected openproject header' do
    it 'sets the expected openproject header' do
      expect(subject['X-OpenProject-Project'].value)
        .to eql project.identifier
    end
  end

  shared_examples_for 'has the expected body' do
    it 'has the expected contents highlighting the roles received' do
      expect(subject.body.parts.detect { |part| part['Content-Type'].value == 'text/html' }.body.to_s)
        .to be_html_eql expected
    end
  end

  describe '#added_project' do
    subject { MemberMailer.added_project(current_user, member) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like 'has a subject', :'mail_member_added_project.subject'
    it_behaves_like 'sets the expected message_id header'
    it_behaves_like 'sets the expected openproject header'
    it_behaves_like 'has the expected body' do
      let(:expected) do
        <<~MSG
          #{current_user.name} added you as a member to the project '#{project.name}'.

          You have the following roles:
          <ul>
            <li> #{roles.first.name} </li>
            <li> #{roles.last.name} </li>
          </ul>
        MSG
      end
    end
    it_behaves_like 'fails for a group'
  end

  describe '#updated_project' do
    subject { MemberMailer.updated_project(current_user, member) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like 'has a subject', :'mail_member_updated_project.subject'
    it_behaves_like 'sets the expected message_id header'
    it_behaves_like 'sets the expected openproject header'
    it_behaves_like 'has the expected body' do
      let(:expected) do
        <<~MSG
          #{current_user.name} updated the roles you have in the project '#{project.name}'.

          You now have the following roles:
          <ul>
            <li> #{roles.first.name} </li>
            <li> #{roles.last.name} </li>
          </ul>
        MSG
      end
    end
    it_behaves_like 'fails for a group'
  end

  describe '#updated_global' do
    let(:project) { nil }

    subject { MemberMailer.updated_global(current_user, member) }

    it_behaves_like "sends a mail to the member's principal"
    it_behaves_like 'has a subject', :'mail_member_updated_global.subject'
    it_behaves_like 'sets the expected message_id header'
    it_behaves_like 'has the expected body' do
      let(:expected) do
        <<~MSG
          #{current_user.name} updated the roles you have globally.

          You now have the following roles:
          <ul>
            <li> #{roles.first.name} </li>
            <li> #{roles.last.name} </li>
          </ul>
        MSG
      end
    end
    it_behaves_like 'fails for a group'
  end
end
