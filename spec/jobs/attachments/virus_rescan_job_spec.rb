# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Attachments::VirusRescanJob,
               with_ee: %i[virus_scanning],
               with_settings: { antivirus_scan_mode: :clamav_socket } do
  let!(:attachment1) { create(:attachment, status: :uploaded) }
  let!(:attachment2) { create(:attachment, status: :rescan) }
  let!(:attachment3) { create(:attachment, status: :rescan) }

  let(:client_double) { instance_double(ClamAV::Client) }

  subject { described_class.perform_now }

  before do
    allow(ClamAV::Client).to receive(:new).and_return(client_double)
  end

  describe "#perform" do
    let(:response) { ClamAV::SuccessResponse.new("wat") }

    before do
      allow(client_double)
        .to receive(:execute).with(instance_of(ClamAV::Commands::InstreamCommand))
                             .and_return(response)
    end

    it "updates the attachments" do
      subject

      expect(attachment1.reload).to be_status_uploaded
      expect(attachment2.reload).to be_status_scanned
      expect(attachment3.reload).to be_status_scanned
    end
  end
end
