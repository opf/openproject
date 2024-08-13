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

RSpec.describe Authorization::EnterpriseService do
  let(:instance) { described_class.new(token) }
  let(:token) { instance_double(EnterpriseToken, token_object:, expired?: expired?) }
  let(:token_object) { OpenProject::Token.new }
  let(:expired?) { false }

  describe "GUARDED_ACTIONS" do
    it "is in alphabetical order" do
      guarded_actions = described_class::GUARDED_ACTIONS

      expect(guarded_actions).to eq(guarded_actions.sort)
    end
  end

  describe "#initialize" do
    it "has the token" do
      expect(instance.token).to eql token
    end
  end

  describe "#call" do
    let(:result) { instance.call(action) }

    shared_examples "true result" do
      it "returns a true result" do
        expect(result).to be_a ServiceResult
        expect(result).to be_success
        expect(result).to have_attributes(result: true)
      end
    end

    shared_examples "false result" do
      it "returns a false result" do
        expect(result).to be_a ServiceResult
        expect(result).not_to be_success
        expect(result).to have_attributes(result: false)
      end
    end

    shared_examples "false result for any action" do
      guarded_action = described_class::GUARDED_ACTIONS.sample

      context "for known action #{guarded_action}" do
        let(:action) { guarded_action }

        include_examples "false result"
      end

      context "for unknown action" do
        let(:action) { "foo" }

        include_examples "false result"
      end
    end

    context "for a valid token" do
      described_class::GUARDED_ACTIONS.each do |guarded_action|
        context "for known action #{guarded_action}" do
          let(:action) { guarded_action }

          include_examples "true result"
        end
      end

      context "for unknown action" do
        let(:action) { "foo" }

        include_examples "false result"
      end
    end

    context "for an expired token" do
      let(:expired?) { true }

      include_examples "false result for any action"
    end

    context "without a token_object" do
      let(:token_object) { nil }

      include_examples "false result for any action"
    end

    context "without a token" do
      let(:token) { nil }

      include_examples "false result for any action"
    end
  end
end
