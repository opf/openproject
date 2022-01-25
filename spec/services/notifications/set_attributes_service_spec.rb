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

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe Notifications::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double('contract_class')

    allow(contract)
      .to receive(:new)
            .with(event, user, options: {})
            .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double('contract_instance', validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double('contract_errors')
  end
  let(:member_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        model: event,
                        contract_class: contract_class)
  end
  let(:call_attributes) { {} }
  let(:project) { build_stubbed(:project) }
  let(:reason) { :mentioned }
  let(:journal) { build_stubbed(:journal, journable: journable, data: journal_data) }
  let(:journable) { nil }
  let(:journal_data) { nil }
  let(:event_subject) { 'I find it important' }
  let(:recipient_id) { 1 }

  describe 'call' do
    let(:call_attributes) do
      {
        recipient_id: recipient_id,
        reason: reason,
        resource: journable,
        journal: journal,
        subject: event_subject,
        project: project
      }
    end

    subject { instance.call(call_attributes) }

    context 'for a new record' do
      let(:event) do
        Notification.new
      end

      it 'is successful' do
        expect(subject)
        .to be_success
      end

      it 'sets the attributes add adds default values' do
        subject

        expect(event.attributes.compact.symbolize_keys)
          .to eql({
                    project_id: project.id,
                    reason: 'mentioned',
                    journal_id: journal.id,
                    recipient_id: 1,
                    subject: event_subject,
                    read_ian: false,
                    mail_reminder_sent: false
                  })
      end

      context 'with only the minimal set of attributes for a notification' do
        let(:journable) do
          build_stubbed(:work_package, project: project).tap do |wp|
            allow(wp)
              .to receive(:to_s)
              .and_return("wp to s")
          end
        end
        let(:journal_data) {
          build_stubbed(:journal_work_package_journal, project: project)
        }
        let(:call_attributes) do
          {
            recipient_id: recipient_id,
            reason: reason,
            journal: journal,
            resource: journable,
          }
        end

        it 'sets the attributes and adds default values that are deduced' do
          subject

          expect(event.attributes.compact.symbolize_keys)
            .to eql({
                      project_id: project.id,
                      reason: 'mentioned',
                      resource_id: journable.id,
                      resource_type: 'WorkPackage',
                      journal_id: journal.id,
                      recipient_id: 1,
                      read_ian: false,
                      mail_reminder_sent: false
                    })
        end
      end

      it 'does not persist the notification' do
        expect(event)
          .not_to receive(:save)

        subject
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
