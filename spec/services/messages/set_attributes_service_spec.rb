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

RSpec.describe Messages::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:forum) { build_stubbed(:forum) }
  let(:contract_instance) do
    contract = double("contract_instance")
    allow(contract)
      .to receive(:validate)
      .and_return(contract_valid)
    allow(contract)
      .to receive(:errors)
      .and_return(contract_errors)
    contract
  end

  let(:contract_errors) { double("contract_errors") }
  let(:contract_valid) { true }
  let(:time_entry_valid) { true }

  let(:instance) do
    described_class.new(user:,
                        model: message_instance,
                        contract_class:,
                        contract_options: {})
  end
  let(:message_instance) { Message.new }
  let(:contract_class) do
    allow(Messages::CreateContract)
      .to receive(:new)
      .with(message_instance, user, options: {})
      .and_return(contract_instance)

    Messages::CreateContract
  end

  let(:params) { {} }

  before do
    allow(message_instance)
      .to receive(:valid?)
      .and_return(time_entry_valid)
  end

  subject { instance.call(params) }

  it "returns the message instance as the result" do
    expect(subject.result)
      .to eql message_instance
  end

  it "is a success" do
    expect(subject)
      .to be_success
  end

  it "has the service's user assigned as author" do
    subject

    expect(message_instance.author)
      .to eql user
  end

  it "notes the author to be system changed" do
    subject

    expect(message_instance.changed_by_system["author_id"])
      .to eql [nil, user.id]
  end

  context "with params" do
    let(:params) do
      {
        forum:
      }
    end

    let(:expected) do
      {
        author_id: user.id,
        forum_id: forum.id
      }.with_indifferent_access
    end

    it "assigns the params" do
      subject

      attributes_of_interest = message_instance
                                 .attributes
                                 .slice(*expected.keys)

      expect(attributes_of_interest)
        .to eql(expected)
    end
  end

  context "with an invalid contract" do
    let(:contract_valid) { false }
    let(:expect_time_instance_save) do
      expect(message_instance)
        .not_to receive(:save)
    end

    it "returns failure" do
      expect(subject)
        .not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
