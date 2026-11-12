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

RSpec.describe Authorization::EnterpriseService do
  let(:instance) { described_class.new(token) }
  let(:token) { instance_double(EnterpriseToken, token_object:, expired?: expired?, invalid_domain?: false) }
  let(:token_object) { OpenProject::Token.new }
  let(:feature) { "some_feature" }
  let(:expired?) { false }

  describe "#initialize" do
    it "has the token" do
      expect(instance.token).to eql token
    end
  end

  describe "#call" do
    let(:result) { instance.call(feature) }

    shared_examples "true result" do
      before do
        allow(token_object).to receive(:has_feature?).with(feature).and_return(true) if token_object
      end

      it "returns a true result" do
        expect(result).to be_a ServiceResult
        expect(result).to be_success
        expect(result).to have_attributes(result: true)
      end
    end

    shared_examples "false result" do
      before do
        allow(token_object).to receive(:has_feature?).with(feature).and_return(false) if token_object
      end

      it "returns a false result" do
        expect(result).to be_a ServiceResult
        expect(result).not_to be_success
        expect(result).to have_attributes(result: false)
      end
    end

    shared_examples "never calls the token object" do
      it "does not call the token object" do
        allow(token_object).to receive(:has_feature?)
        result
        expect(token_object).not_to have_received(:has_feature?)
      end
    end

    context "for a valid token" do
      let(:expired?) { false }

      include_examples "true result"
    end

    context "for an expired token" do
      let(:expired?) { true }

      include_examples "never calls the token object"
      include_examples "false result"
    end

    context "without a token_object" do
      let(:token_object) { nil }

      include_examples "false result"
    end

    context "without a token" do
      let(:token) { nil }

      include_examples "never calls the token object"
      include_examples "false result"
    end
  end
end
