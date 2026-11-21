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

RSpec.describe ITSM do
  context "when the help desk was turned on" do
    before { ITSM::HelpdeskUsers::SetUpService.new.call }

    it "finds the help desk user and role" do
      expect(described_class.helpdesk_user).to be_a(ServiceAccount).and have_attributes(name: "Help desk")
      expect(described_class.helpdesk_role).to be_a(ITSM::HelpdeskRole).and have_attributes(name: "Help desk")
    end
  end

  context "when the help desk was not turned on yet" do
    it "finds nothing and creates nothing" do
      expect do
        expect(described_class.helpdesk_user).to be_nil
        expect(described_class.helpdesk_role).to be_nil
      end.not_to change(Principal, :count)
    end
  end

  describe ".helpdesk_available_in?", with_flag: { helpdesk: true }, with_settings: { helpdesk_enabled: true } do
    subject { described_class.helpdesk_available_in?(project) }

    let(:project) { create(:project, enabled_module_names: %w[helpdesk]) }

    it { is_expected.to be(true) }

    context "when the help desk is turned off", with_settings: { helpdesk_enabled: false } do
      it { is_expected.to be(false) }
    end

    context "when the project does not use the help desk" do
      let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }

      it { is_expected.to be(false) }
    end

    context "when the project is archived" do
      let(:project) { create(:project, active: false, enabled_module_names: %w[helpdesk]) }

      it { is_expected.to be(false) }
    end
  end

  describe ".helpdesk_addresses" do
    before do
      create(:itsm_incoming_mailbox, email: "support@example.com", aliases: ["help@example.com"])
      create(:itsm_outgoing_mailbox, sender_email: "desk@example.com")
    end

    it "returns the addresses of every incoming and outgoing mailbox" do
      expect(described_class.helpdesk_addresses).to contain_exactly("support@example.com", "help@example.com", "desk@example.com")
    end
  end
end
