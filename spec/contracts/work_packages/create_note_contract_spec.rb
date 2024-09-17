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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe WorkPackages::CreateNoteContract do
  let(:work_package) do
    # As we only want to test the contract, we mock checking whether the work_package is valid
    wp = build_stubbed(:work_package)
    # we need to clear the changes information because otherwise the
    # contract will complain about all the changes to read_only attributes
    wp.send(:clear_changes_information)
    allow(wp).to receive(:valid?).and_return true

    wp
  end
  let(:user) { build_stubbed(:user) }
  let(:policy_instance) { double("WorkPackagePolicyInstance") }

  subject(:contract) do
    contract = described_class.new(work_package, user)

    contract.send(:"policy=", policy_instance)

    contract
  end

  describe "note" do
    before do
      work_package.journal_notes = "blubs"
    end

    context "if the user has the permissions" do
      before do
        allow(policy_instance).to receive(:allowed?).with(work_package, :comment).and_return true

        contract.validate
      end

      it("is valid") { expect(contract.errors).to be_empty }
    end

    context "if the user lacks the permissions" do
      before do
        allow(policy_instance).to receive(:allowed?).with(work_package, :comment).and_return false

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:journal_notes))
          .to contain_exactly(:error_unauthorized)
      end
    end
  end

  describe "subject" do
    before do
      work_package.subject = "blubs"

      allow(policy_instance).to receive(:allowed?).and_return true

      contract.validate
    end

    it "is invalid" do
      expect(contract.errors.symbols_for(:subject))
        .to contain_exactly(:error_readonly)
    end
  end
end
