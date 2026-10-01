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

RSpec.describe ServiceResult, type: :model do
  let(:instance) { described_class.new }

  describe "success" do
    it "is what the service is initialized with" do
      instance = described_class.new success: true

      expect(instance.success).to be_truthy
      expect(instance.success?).to be(true)

      instance = described_class.new success: false

      expect(instance.success).to be_falsey
      expect(instance.success?).to be(false)
    end

    it "returns what is provided" do
      instance.success = true

      expect(instance.success).to be_truthy
      expect(instance.success?).to be(true)

      instance.success = false

      expect(instance.success).to be_falsey
      expect(instance.success?).to be(false)
    end

    it "is false by default" do
      expect(instance.success).to be_falsey
      expect(instance.success?).to be(false)
    end
  end

  describe ".success" do
    it "creates a ServiceResult with success: true" do
      instance = described_class.success
      expect(instance.success).to be_truthy
    end

    it "accepts the same set of parameters as the initializer" do
      errors = ["errors"]
      message = "message"
      message_type = :message_type
      state = instance_double(Shared::ServiceState)
      dependent_results = ["dependent_results"]
      result = instance_double(Object, "result")

      instance = described_class.success(
        errors:,
        message:,
        message_type:,
        state:,
        dependent_results:,
        result:
      )

      expect(instance.errors).to be(errors)
      expect(instance.message).to be(message)
      expect(instance.state).to be(state)
      expect(instance.dependent_results).to be(dependent_results)
      expect(instance.result).to be(result)
    end
  end

  describe ".failure" do
    it "creates a ServiceResult with success: false" do
      instance = described_class.failure
      expect(instance.success).to be_falsy
    end

    it "accepts the same set of parameters as the initializer" do
      errors = ["errors"]
      message = "message"
      message_type = :message_type
      state = instance_double(Shared::ServiceState)
      dependent_results = ["dependent_results"]
      result = instance_double(Object, "result")

      instance = described_class.failure(
        errors:,
        message:,
        message_type:,
        state:,
        dependent_results:,
        result:
      )

      expect(instance.errors).to be(errors)
      expect(instance.message).to be(message)
      expect(instance.state).to be(state)
      expect(instance.dependent_results).to be(dependent_results)
      expect(instance.result).to be(result)
    end
  end

  describe "errors" do
    let(:errors) { ["errors"] }

    it "is what has been provided" do
      instance.errors = errors

      expect(instance.errors).to eql errors
    end

    it "is what the object is initialized with" do
      instance = described_class.new(errors:)

      expect(instance.errors).to eql errors
    end

    it "is an empty ActiveModel::Errors by default" do
      expect(instance.errors).to be_a ActiveModel::Errors
    end

    context "when providing errors from user" do
      let(:result) { build(:work_package) }

      it "creates a new errors instance" do
        instance = described_class.new(result:)
        expect(instance.errors).not_to eq result.errors
      end
    end

    context "when using default errors" do
      it "uses the default human_attribute_name from ServiceResult (Regression #61483)" do
        instance = described_class.new
        instance.errors.add(:base, "some error")
        instance.errors.add(:foo, "an error for foo")

        expect { instance.errors.full_messages }.not_to raise_error
      end
    end

    context "when providing active record result" do
      let(:result) { build(:work_package) }

      it "creates a new errors instance" do
        instance = described_class.new(result:)
        base = instance.errors.instance_eval { @base } # rubocop:disable RSpec/InstanceVariable
        expect(base).to eq(result)
      end
    end

    context "when providing some other result" do
      let(:result) { "wat?" }

      it "creates a new errors instance" do
        instance = described_class.new(result:)
        base = instance.errors.instance_eval { @base } # rubocop:disable RSpec/InstanceVariable
        expect(base).to eq(instance)
      end
    end

    context "when using default errors from result" do
      let(:result) { build(:work_package) }

      it "uses the result's human_attribute_name" do
        instance = described_class.new(result:)
        instance.errors.add(:base, "some error")
        instance.errors.add(:foo, "an error for foo")

        expect { instance.errors.full_messages }.not_to raise_error
      end
    end
  end

  describe "result" do
    let(:result) { instance_double(Object, "result") }

    it "is what the object is initialized with" do
      instance = described_class.new(result:)

      expect(instance.result).to eql result
    end

    it "is what has been provided" do
      instance.result = result

      expect(instance.result).to eql result
    end

    it "is nil by default" do
      instance = described_class.new

      expect(instance.result).to be_nil
    end
  end

  describe "apply_flash_message!" do
    let(:message) { "some message" }

    subject(:flash) do
      {}.tap { service_result.apply_flash_message!(it) }
    end

    context "when successful" do
      let(:service_result) { described_class.success(message:) }

      it { is_expected.to include(notice: message) }
    end

    context "when failure" do
      let(:service_result) { described_class.failure(message:) }

      it { is_expected.to include(error: message) }
    end

    context "when setting message_type to :info" do
      let(:service_result) { described_class.success(message:, message_type: :info) }

      it { is_expected.to include(info: message) }
    end
  end

  describe "#bind" do
    context "when successful" do
      let(:first) { described_class.success(result: 42) }

      it "calls the block with the result and returns the block's ServiceResult" do
        returned = first.bind { |r| described_class.success(result: r * 2) }

        expect(returned).to be_success
        expect(returned.result).to eq(84)
      end

      it "returns the failure from the block when the block fails" do
        failure = described_class.failure(message: "step 2 failed")

        returned = first.bind { failure }

        expect(returned).to be(failure)
        expect(returned.message).to eq("step 2 failed")
      end
    end

    context "when failed" do
      let(:first) { described_class.failure(message: "step 1 failed") }

      it "returns self without calling the block" do
        expect { |b| first.bind(&b) }.not_to yield_control

        expect(first.bind { described_class.success }).to be(first)
      end
    end

    context "when chaining multiple calls" do
      it "returns the last success when all succeed" do
        result = described_class.success(result: 1)
          .bind { |r| described_class.success(result: r + 1) }
          .bind { |r| described_class.success(result: r + 1) }

        expect(result).to be_success
        expect(result.result).to eq(3)
      end

      it "short-circuits at the first failure" do
        second_called = false
        failure = described_class.failure(message: "failed")

        result = described_class.success(result: 1)
          .bind { failure }
          .bind do
            second_called = true
            described_class.success
          end

        expect(result).to be(failure)
        expect(result.message).to eq("failed")
        expect(second_called).to be(false)
      end
    end
  end
end
