# frozen_string_literal: true

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

RSpec.describe OAuth::Applications::SetAttributesService, type: :model do # rubocop:disable RSpec/SpecFilePathFormat
  let(:current_user) { build_stubbed(:admin) }

  let(:contract_instance) do
    contract = instance_double(OAuth::Applications::CreateContract, "contract_instance")
    allow(contract).to receive_messages(validate: contract_valid, errors: contract_errors)
    contract
  end

  let(:contract_errors) { instance_double(ActiveModel::Errors, "contract_errors") }
  let(:contract_valid) { true }
  let(:model_valid) { true }

  let(:instance) do
    described_class.new(user: current_user,
                        model: model_instance,
                        contract_class:,
                        contract_options: {})
  end
  let(:model_instance) { Doorkeeper::Application.new }
  let(:contract_class) do
    allow(OAuth::Applications::CreateContract)
      .to receive(:new)
            .and_return(contract_instance)

    OAuth::Applications::CreateContract
  end

  let(:params) { { name: "My app" } }

  before do
    allow(model_instance)
      .to receive(:valid?)
      .and_return(model_valid)
  end

  subject { instance.call(params) }

  it "returns the instance as the result" do
    expect(subject.result)
      .to eql model_instance
  end

  it "is a success" do
    expect(subject)
      .to be_success
  end

  context "with new record" do
    it "sets owner to current user" do
      expect(subject.result.owner_id).to eq current_user.id
      expect(subject.result.owner_type).to eq "User"
    end
  end

  context "with an invalid contract" do
    let(:contract_valid) { false }

    it "returns failure" do
      expect(subject).not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
