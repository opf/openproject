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

RSpec.describe Groups::SetAttributesService, type: :model do
  subject(:service_call) { instance.call(call_attributes) }

  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double("contract_class")

    allow(contract)
      .to receive(:new)
      .with(group, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    instance_double(ModelContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveRecord::ActiveRecordError)
  end
  let(:group_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: group,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:group) do
    build_stubbed(:group) do |g|
      # To later check that it has not been called
      allow(g)
        .to receive(:save)
    end
  end

  describe "call" do
    let(:call_attributes) do
      {
        name: "The name"
      }
    end

    before do
      allow(group)
        .to receive(:valid?)
        .and_return(group_valid)

      allow(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "sets the attributes" do
      service_call

      expect(group.lastname)
        .to eql call_attributes[:name]
    end

    it "does not persist the group" do
      service_call

      expect(group)
        .not_to have_received(:save)
    end

    context "with no changes to the users" do
      let(:call_attributes) do
        {
          name: "My new group name"
        }
      end
      let(:first_user) { build_stubbed(:user) }
      let(:second_user) { build_stubbed(:user) }
      let(:first_group_user) { build_stubbed(:group_user, user: first_user) }
      let(:second_group_user) { build_stubbed(:group_user, user: second_user) }

      let(:group) do
        build_stubbed(:group, group_users: [first_group_user, second_group_user])
      end

      let(:updated_group) do
        service_call.result
      end

      it "does not change the users (Regression #38017)" do
        expect(updated_group.name).to eq "My new group name"
        expect(updated_group.group_users.map(&:user_id))
          .to eql [first_user.id, second_user.id]

        expect(updated_group.group_users.any?(&:marked_for_destruction?)).to be false
      end
    end

    context "with changes to the users do" do
      let(:first_user) { build_stubbed(:user) }
      let(:second_user) { build_stubbed(:user) }
      let(:third_user) { build_stubbed(:user) }

      let(:call_attributes) do
        {
          user_ids: [second_user.id, third_user.id]
        }
      end

      shared_examples_for "updates the users" do
        let(:first_group_user) { build_stubbed(:group_user, user: first_user) }
        let(:second_group_user) { build_stubbed(:group_user, user: second_user) }

        let(:group) do
          build_stubbed(:group, group_users: [first_group_user, second_group_user])
        end

        it "adds the new users" do
          expect(service_call.result.group_users.map(&:user_id))
            .to eql [first_user.id, second_user.id, third_user.id]
        end

        it "does not persist the new association" do
          expect(service_call.result.group_users.find { |gu| gu.user_id == third_user.id })
            .to be_new_record
        end

        it "keeps the association already existing before" do
          expect(service_call.result.group_users.find { |gu| gu.user_id == second_user.id })
            .not_to be_marked_for_destruction
        end

        it "marks not mentioned users to be removed" do
          expect(service_call.result.group_users.find { |gu| gu.user_id == first_user.id })
            .to be_marked_for_destruction
        end
      end

      context "with a persisted record and integer values" do
        let(:call_attributes) do
          {
            user_ids: [second_user.id, third_user.id]
          }
        end

        it_behaves_like "updates the users"
      end

      context "with a persisted record and string values" do
        let(:call_attributes) do
          {
            user_ids: [second_user.id.to_s, third_user.id.to_s]
          }
        end

        it_behaves_like "updates the users"
      end

      context "with a new record" do
        let(:group) do
          Group.new
        end

        it "sets the user" do
          expect(service_call.result.group_users.map(&:user_id))
            .to eql [second_user.id, third_user.id]
        end

        it "does not persist the association" do
          expect(service_call.result.group_users.all(&:new_record?))
            .to be_truthy
        end
      end
    end
  end
end
