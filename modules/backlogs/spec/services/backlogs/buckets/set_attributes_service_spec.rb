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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Backlogs::Buckets::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = class_double(Backlogs::Buckets::CreateContract)

    allow(contract)
      .to receive(:new)
      .with(backlog_bucket, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    instance_double(ModelContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:backlog_bucket_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: backlog_bucket,
                        contract_class:,
                        contract_options: {})
  end
  let(:project) { create(:project) }
  let(:backlog_bucket) { BacklogBucket.new }
  let(:params) { { project: } }

  subject(:service_call) { instance.call(params) }

  describe "call" do
    before do
      allow(backlog_bucket)
        .to receive(:valid?)
        .and_return(backlog_bucket_valid)

      allow(backlog_bucket).to receive(:save)
    end

    context "when contract validates and backlog bucket is valid" do
      it "is successful" do
        expect(service_call).to be_success
      end

      it "does not persist the backlog bucket" do
        service_call

        expect(backlog_bucket).not_to have_received(:save)
      end
    end

    context "when contract does not validate" do
      let(:contract_valid) { false }

      it "is not successful" do
        expect(service_call).not_to be_success
      end
    end

    context "with params" do
      let(:params) do
        {
          name: "Blah Blah"
        }
      end

      before do
        allow(contract_instance)
          .to receive(:validate)
          .and_return(true)
      end

      it "passes the params to the backlog bucket" do
        service_call

        expect(backlog_bucket.name).to eq("Blah Blah")
      end
    end
  end
end
