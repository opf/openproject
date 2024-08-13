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
  let(:token_object) do
    token = OpenProject::Token.new
    token.subscriber = "Foobar"
    token.mail = "foo@example.org"
    token.starts_at = Date.today
    token.expires_at = nil

    token
  end
  let(:token) { double("EnterpriseToken", token_object:) }
  let(:instance) { described_class.new(token) }
  let(:result) { instance.call(action) }
  let(:action) { :an_action }

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

  describe "expiry" do
    before do
      allow(token).to receive(:expired?).and_return(expired)
    end

    context "when expired" do
      let(:expired) { true }

      it "returns a false result" do
        expect(result).to be_a ServiceResult
        expect(result.result).to be_falsey
        expect(result.success?).to be_falsey
      end
    end

    context "when active" do
      let(:expired) { false }

      context "invalid action" do
        it "returns false" do
          expect(result.result).to be_falsey
        end
      end

      %i(baseline_comparison
         board_view
         conditional_highlighting
         custom_actions
         custom_fields_in_projects_list
         date_alerts
         define_custom_style
         edit_attribute_groups
         grid_widget_wp_graph
         ldap_groups
         openid_providers
         placeholder_users
         readonly_work_packages
         team_planner_view
         two_factor_authentication
         work_package_query_relation_columns
         work_package_sharing).each do |guarded_action|
        context "guarded action #{guarded_action}" do
          let(:action) { guarded_action }

          it "returns a true result" do
            expect(result).to be_a ServiceResult
            expect(result.result).to be_truthy
            expect(result.success?).to be_truthy
          end
        end
      end
    end
  end
end
