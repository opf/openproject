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

require "spec_helper"
require_module_spec_helper

RSpec.describe ITSM::EmailThread do
  subject(:thread) { build(:itsm_email_thread, work_package:, requester_email:, recipients:) }

  let(:work_package) { create(:work_package) }
  let(:requester_email) { "Requester@Customer.example" }
  let(:recipients) { [] }

  it { is_expected.to be_valid }

  it "normalizes the requester email" do
    expect(thread.requester_email).to eq("requester@customer.example")
  end

  context "with recipients" do
    let(:recipients) { [" Jane@Customer.example", "", "jane@customer.example", "bob@customer.example"] }

    it "normalizes them" do
      expect(thread.recipients).to eq(%w[jane@customer.example bob@customer.example])
    end
  end

  context "without a work package" do
    let(:work_package) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when the work package already has a thread" do
    let!(:existing) { create(:itsm_email_thread, work_package:) }

    it { is_expected.not_to be_valid }
  end

  context "when its work package is deleted" do
    let!(:saved_thread) { create(:itsm_email_thread, work_package:) }
    let!(:message) { create(:itsm_email_message, thread: saved_thread) }

    it "is deleted together with its messages" do
      work_package.destroy

      expect(described_class).not_to exist(saved_thread.id)
      expect(ITSM::EmailMessage).not_to exist(message.id)
    end
  end
end
