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
require 'contracts/shared/model_contract_shared_context'

describe Notifications::CreateContract do
  include_context 'ModelContract shared context'

  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
    end
  end

  let(:event_context) { FactoryBot.build_stubbed(:project) }
  let(:event_resource) { FactoryBot.build_stubbed(:journal) }
  let(:event_recipient) { FactoryBot.build_stubbed(:user) }
  let(:event_subject) { 'Some text' }
  let(:event_reason) { :mentioned }

  let(:event) do
    Notification.new(context: event_context,
                     recipient: event_recipient,
                     subject: event_subject,
                     reason: event_reason,
                     resource: event_resource)
  end

  let(:contract) { described_class.new(event, current_user) }

  describe '#validation' do
    it_behaves_like 'contract is valid'

    context 'without a recipient' do
      let(:event_recipient) { nil }

      it_behaves_like 'contract is invalid', recipient: :blank
    end

    context 'without a reason' do
      let(:event_reason) { nil }

      it_behaves_like 'contract is invalid', reason: :blank
    end

    context 'without a subject' do
      let(:event_subject) { nil }

      it_behaves_like 'contract is invalid', subject: :blank
    end

    context 'with an empty subject' do
      let(:event_subject) { '' }

      it_behaves_like 'contract is invalid', subject: :blank
    end
  end
end
