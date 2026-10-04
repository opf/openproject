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
require "services/base_services/behaves_like_create_service"

RSpec.describe EnterpriseTrials::CreateService, type: :model do
  let(:user) { build_stubbed(:admin) }
  let(:instance) { described_class.new(user:) }
  let(:valid_params) do
    {
      company: "Foo Corp",
      firstname: "Albert",
      lastname: "Einstein",
      email: "a.einstein@example.com",
      newsletter_consent: true,
      general_consent: true
    }
  end
  let(:params) { valid_params }
  let(:augur_double) { instance_double(EnterpriseTrials::AugurCreateTrialService) }
  let(:augur_result) { ServiceResult.success(result: nil) }

  subject { instance.call(params) }

  before do
    allow(EnterpriseTrials::AugurCreateTrialService).to receive(:new).and_return(augur_double)
    allow(augur_double).to receive(:call).and_return(augur_result)
  end

  context "with valid params" do
    it "requests a trial request using the AugurCreateTrialService" do
      expect(subject).to be_success
      expect(augur_double).to have_received(:call)
    end
  end

  context "with invalid params" do
    let(:params) { valid_params.merge(email: "invalid_email") }

    it "returns an error" do
      expect(subject).to be_failure
      expect(subject.errors.symbols_for(:email)).to contain_exactly(:email)
    end
  end

  context "when user is not an admin" do
    let(:user) { build_stubbed(:user) }

    it "returns an error" do
      expect(subject).to be_failure
      expect(subject.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
    end
  end
end
