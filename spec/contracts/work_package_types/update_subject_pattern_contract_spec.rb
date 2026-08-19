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

module WorkPackageTypes
  RSpec.describe UpdateSubjectPatternContract, with_ee: [:work_package_subject_generation] do
    let(:model) { create(:type, :with_subject_pattern) }
    let(:user) { create(:admin) }

    subject(:contract) { described_class.new(model, user) }

    context "when the user isn't admin" do
      let(:user) { create(:user) }

      it "the contract is invalid" do
        expect(contract.validate).to be_falsey
      end

      it "adds an error to the contract" do
        contract.validate
        expect(contract.errors.details).to eq(base: [{ error: :error_unauthorized }])
      end
    end

    context "if there is no enterprise token that allows subject configuration", with_ee: [] do
      it "adds an error to the contract" do
        contract.validate
        expect(contract.errors.details)
          .to eq(patterns: [{ action: "Work Package Subject Generation", error: :error_enterprise_only }])
      end

      context "with manual subject configuration" do
        let(:model) { create(:type) }

        it "succeeds" do
          expect(contract.validate).to be_truthy
        end
      end
    end

    describe "subject_pattern validation" do
      let(:valid_pattern) { { subject: { blueprint: "{{author}}", enabled: true } } }
      let(:invalid_pattern) { { subject: { blueprint: "{{vader_s_rubber_duck}}", enabled: true } } }

      context "with no previous subject patterns" do
        let(:model) { create(:type) }

        it "is valid with a valid pattern" do
          model.patterns = valid_pattern
          expect(contract.validate).to be_truthy
        end

        it "is invalid if the pattern has bad tokens" do
          model.patterns = invalid_pattern
          expect(contract.validate).to be_falsey
        end

        it "adds an error if the pattern has bad tokens" do
          model.patterns = invalid_pattern
          contract.validate

          expect(contract.errors.details).to eq(patterns: [{ error: :invalid_tokens }])
        end
      end

      context "with a valid subject pattern" do
        it "succeeds" do
          model.patterns = valid_pattern
          expect(model.validate).to be_truthy
        end
      end
    end
  end
end
