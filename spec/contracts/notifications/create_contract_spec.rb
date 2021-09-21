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
require 'contracts/shared/model_contract_shared_context'

describe Notifications::CreateContract do
  include_context 'ModelContract shared context'

  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
    end
  end

  let(:notification_context) { FactoryBot.build_stubbed(:project) }
  let(:notification_resource) { FactoryBot.build_stubbed(:journal) }
  let(:notification_recipient) { FactoryBot.build_stubbed(:user) }
  let(:notification_subject) { 'Some text' }
  let(:notification_reason) { :mentioned }
  let(:notification_read_ian) { false }
  let(:notification_sent_mail) { false }

  let(:notification) do
    Notification.new(project: notification_context,
                     recipient: notification_recipient,
                     subject: notification_subject,
                     reason: notification_reason,
                     resource: notification_resource,
                     read_ian: notification_read_ian,
                     sent_mail: notification_sent_mail)
  end

  let(:contract) { described_class.new(notification, current_user) }

  describe '#validation' do
    it_behaves_like 'contract is valid'

    context 'without a recipient' do
      let(:notification_recipient) { nil }

      it_behaves_like 'contract is invalid', recipient: :blank
    end

    context 'without a reason for IAN with read_ian false' do
      let(:notification_reason) { nil }
      let(:notification_read_ian) { false }

      it_behaves_like 'contract is invalid', reason: :no_notification_reason
    end

    context 'without a reason for IAN with read_ian nil' do
      let(:notification_reason) { nil }
      let(:notification_read_ian) { nil }

      it_behaves_like 'contract is invalid', reason: :no_notification_reason
    end

    context 'without a subject' do
      let(:notification_subject) { nil }

      it_behaves_like 'contract is valid'
    end

    context 'with an empty subject' do
      let(:notification_subject) { '' }

      it_behaves_like 'contract is valid'
    end

    context 'with read_ian true' do
      let(:notification_read_ian) { true }

      it_behaves_like 'contract is invalid', read_ian: :read_on_creation
    end

    context 'with sent_mail true' do
      let(:notification_sent_mail) { true }

      it_behaves_like 'contract is invalid', sent_mail: :set_on_creation
    end
  end
end
