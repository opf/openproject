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

require_relative "../spec_helper"

RSpec.describe OpenProject::TwoFactorAuthentication::TokenStrategyManager do
  let(:dev_strategy) { OpenProject::TwoFactorAuthentication::TokenStrategy::Developer }
  let(:totp_strategy) { OpenProject::TwoFactorAuthentication::TokenStrategy::Totp }
  let(:configuration) do
    {
      active_strategies:,
      enforced:
    }
  end
  let(:enforced) { false }

  include_context "with settings" do
    let(:settings) do
      {
        plugin_openproject_two_factor_authentication: configuration
      }
    end
  end

  describe "#find_matching_strategy" do
    subject { described_class.find_matching_strategy(:sms) }

    context "when no strategy is set" do
      let(:active_strategies) { [] }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when matching strategy exists" do
      let(:active_strategies) { [:developer] }

      it "returns the strategy" do
        expect(subject).to eq(dev_strategy)
      end
    end

    context "when non-matching strategy exists" do
      let(:active_strategies) { [:totp] }

      it "returns the strategy" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#active_strategies" do
    context "with bogus strategy" do
      let(:active_strategies) { [:doesnotexist] }

      it "raises when accessing" do
        expect { described_class.active_strategies }.to raise_error(ArgumentError)
      end

      it "raises when validating" do
        expect { described_class.validate_active_strategies! }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#validate_active_strategies!" do
    subject { described_class.validate_active_strategies! }

    context "when no strategy is set" do
      let(:active_strategies) { [] }

      before do
        allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
          .to receive(:add_default_strategy?)
                .and_return false
      end

      context "when enforced is false" do
        let(:enforced) { false }

        it "accepts that" do
          expect { subject }.not_to raise_error
          expect(described_class).not_to be_enabled
          expect(described_class).not_to be_enforced
        end
      end

      context "when enforced is true" do
        let(:enforced) { true }

        it "raises and error that a strategy is needed" do
          expect { subject }.to raise_error(ArgumentError)
          expect(described_class).not_to be_enabled
          expect(described_class).to be_enforced
        end
      end
    end

    context "when a strategy is set" do
      let(:active_strategies) { [:developer] }

      context "when it is valid" do
        it "returns that" do
          expect { subject }.not_to raise_error
          expect(described_class.active_strategies).to eq([dev_strategy])
          expect(described_class).to be_enabled
          expect(described_class).not_to be_enforced
        end
      end

      context "when it is invalid" do
        it "raises" do
          allow(dev_strategy).to receive(:validate!).and_raise "Error!"

          expect { subject }.to raise_error "Error!"
          expect(described_class).to be_enabled
          expect(described_class).not_to be_enforced
        end
      end
    end
  end
end
