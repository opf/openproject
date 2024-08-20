#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Notifications::CreateService, "integration", type: :model do
  let(:work_package) { create(:work_package) }
  let(:journal) { work_package.journals.first }
  let(:instance) { described_class.new(user: actor) }
  let(:attributes) { {} }
  let(:actor) { current_user }
  let(:recipient) { create(:user) }
  let(:service_result) do
    instance
      .call(**attributes)
  end

  current_user { create(:user) }

  describe "#call" do
    let(:attributes) do
      {
        recipient:,
        resource: work_package,
        journal:,
        actor:,
        read_ian: false,
        reason: :mentioned,
        mail_reminder_sent: nil,
        mail_alert_sent: nil
      }
    end

    it "creates a notification" do
      # successful
      expect { service_result }
        .to change(Notification, :count)
              .by(1)

      expect(service_result)
        .to be_success
    end

    context "with the journal being deleted in the meantime (e.g. via a different process)" do
      before do
        Journal.where(id: journal.id).delete_all
      end

      it "creates no notification" do
        # successful
        expect { service_result }
          .not_to change(Notification, :count)

        expect(service_result)
          .to be_failure

        expect(service_result.errors.details[:journal_id])
          .to contain_exactly({ error: :does_not_exist })
      end
    end
  end
end
