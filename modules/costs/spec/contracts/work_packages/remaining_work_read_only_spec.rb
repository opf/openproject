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

RSpec.describe WorkPackages::RemainingWorkReadOnly, type: :model do
  let(:logged_time_reduces_remaining_work) { true }
  let(:remaining_work_read_only) { true }
  let(:project) do
    create(:project, logged_time_reduces_remaining_work:, remaining_work_read_only:)
  end
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end
  let(:work_package) { create(:work_package, project:, estimated_hours: 5.0, remaining_hours: 5.0, done_ratio: 0) }

  describe "writability in the update contract" do
    subject(:contract) { WorkPackages::UpdateContract.new(work_package, user) }

    it "makes remaining work and % complete read only" do
      expect(contract.writable?(:remaining_hours)).to be(false)
      expect(contract.writable?(:done_ratio)).to be(false)
    end

    it "keeps work writable" do
      expect(contract.writable?(:estimated_hours)).to be(true)
    end

    context "when logged time does not reduce remaining work" do
      let(:logged_time_reduces_remaining_work) { false }

      it "keeps remaining work and % complete writable" do
        expect(contract.writable?(:remaining_hours)).to be(true)
        expect(contract.writable?(:done_ratio)).to be(true)
      end
    end

    context "when remaining work is not read only" do
      let(:remaining_work_read_only) { false }

      it "keeps remaining work and % complete writable" do
        expect(contract.writable?(:remaining_hours)).to be(true)
        expect(contract.writable?(:done_ratio)).to be(true)
      end
    end
  end

  describe "writability in the create contract" do
    subject(:contract) { WorkPackages::CreateContract.new(WorkPackage.new(project:), user) }

    it "keeps remaining work and % complete writable" do
      expect(contract.writable?(:remaining_hours)).to be(true)
      expect(contract.writable?(:done_ratio)).to be(true)
    end
  end

  describe "updating a work package" do
    subject(:update_call) { WorkPackages::UpdateService.new(user:, model: work_package).call(params) }

    context "when changing remaining work" do
      let(:params) { { remaining_hours: 2.0 } }

      it "fails" do
        expect(update_call).to be_failure
        expect(update_call.errors.symbols_for(:remaining_hours)).to include(:error_readonly)
      end
    end

    context "when changing % complete" do
      let(:params) { { done_ratio: 50 } }

      it "fails" do
        expect(update_call).to be_failure
        expect(update_call.errors.symbols_for(:done_ratio)).to include(:error_readonly)
      end
    end

    context "when changing work" do
      let(:params) { { estimated_hours: 8.0 } }

      it "derives remaining work" do
        expect(update_call).to be_success
        expect(work_package.reload.remaining_hours).to eq(8.0)
      end
    end
  end
end
