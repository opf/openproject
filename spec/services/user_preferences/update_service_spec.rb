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
#++

require "spec_helper"
require "services/base_services/behaves_like_update_service"

RSpec.describe UserPreferences::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:params_success) { true }
    let(:params_errors) { ActiveModel::Errors.new({}) }
    let(:params_contract) do
      instance_double(UserPreferences::ParamsContract, valid?: params_success, errors: params_errors)
    end

    before do
      allow(UserPreferences::ParamsContract).to receive(:new).and_return(params_contract)
    end

    context "when the params contract is invalid" do
      let(:params_success) { false }

      it "returns that error" do
        expect(subject).to be_failure
        expect(subject.errors).to eq(params_errors)
      end
    end
  end
end
