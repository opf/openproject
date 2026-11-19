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

RSpec.describe ApplicationController, "enforcement of enterprise feature guards" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user) { create(:user) }
  let(:feature_key) { "some_enterprise_feature" }
  let(:plan) { "enterprise" }

  controller_setup = Module.new do
    extend ActiveSupport::Concern

    included do
      # These calls prevent the RuntimeError about authorization checks being required
      # They tell the controller that authorization has been handled separately
      # In real usage, the enterprise guard itself would be the authorization check
      authorization_checked! :index
      authorization_checked! :alternative_action

      def index
        render plain: "OK"
      end

      def alternative_action
        render plain: "OK"
      end

      private

      def other_before_action; end
    end
  end

  current_user { user }

  shared_examples "succeeds" do |action_name = :index|
    it "succeeds" do
      get action_name

      expect(response)
        .to have_http_status :ok
    end
  end

  shared_examples "is blocked" do |action_name = :index|
    it "returns 403 forbidden" do
      get action_name

      expect(response)
        .to have_http_status :forbidden
    end
  end

  shared_examples "redirects" do |action_name = :index|
    it "redirects" do
      get action_name

      expect(response)
        .to have_http_status :redirect
    end
  end

  before do
    allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(false)
    allow(OpenProject::Token).to receive(:lowest_plan_for).with(feature_key).and_return(plan)
  end

  context "with feature check using guard_enterprise_feature" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      guard_enterprise_feature "some_enterprise_feature"
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    context "when enterprise token allows the feature" do
      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(true)
      end

      it_behaves_like "succeeds"
    end
  end

  context "with feature check using guard_enterprise_feature on a single action" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      guard_enterprise_feature "some_enterprise_feature", only: %i[index]

      # Mark alternative_action as having authorization checked separately
      # since it's not guarded by enterprise_feature
      authorization_checked! :alternative_action
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    it "allows other actions" do
      get :alternative_action

      expect(response)
        .to have_http_status :ok
    end
  end

  context "with feature check using guard_enterprise_feature except for an action" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      guard_enterprise_feature "some_enterprise_feature", except: %i[alternative_action]

      # Mark alternative_action as having authorization checked separately
      # since it's not guarded by enterprise_feature
      authorization_checked! :alternative_action
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    it "allows the excepted action" do
      get :alternative_action

      expect(response)
        .to have_http_status :ok
    end
  end

  context "with feature check using guard_enterprise_feature with a custom block" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      guard_enterprise_feature "some_enterprise_feature" do
        redirect_to "/custom/path"
      end

      # No need for explicit authorization_checked! calls here since guard_enterprise_feature
      # should implicitly mark actions as authorized
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "redirects"

    it "sets a flash error message" do
      get :index

      expect(flash[:error]).to be_present
      expect(flash[:error]).to include(plan)
    end
  end

  context "with feature check in the superclass" do
    controller(described_class) do
      include Accounts::EnterpriseGuard
      guard_enterprise_feature "some_enterprise_feature"
    end

    controller(controller_class) do
      include controller_setup
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    context "when enterprise token allows the feature" do
      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(true)
      end

      it_behaves_like "succeeds"
    end
  end

  context "with feature check via prepend_before_action" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      prepend_before_action { perform_enterprise_feature_guard("some_enterprise_feature") }

      # Explicitly mark actions as having authorization checked
      authorization_checked! :index
      authorization_checked! :alternative_action
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    context "when enterprise token allows the feature" do
      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(true)
      end

      it_behaves_like "succeeds"
    end
  end

  context "with feature check via append_before_action" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      append_before_action { perform_enterprise_feature_guard("some_enterprise_feature") }

      # Explicitly mark actions as having authorization checked
      authorization_checked! :index
      authorization_checked! :alternative_action
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    context "when enterprise token allows the feature" do
      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(true)
      end

      it_behaves_like "succeeds"
    end
  end

  context "with multiple feature checks" do
    controller do
      include Accounts::EnterpriseGuard
      include controller_setup

      guard_enterprise_feature "some_enterprise_feature", only: %i[index]
      guard_enterprise_feature "another_enterprise_feature", only: %i[alternative_action]
    end

    before do
      allow(EnterpriseToken).to receive(:allows_to?).with("another_enterprise_feature").and_return(false)
      allow(OpenProject::Token).to receive(:lowest_plan_for).with("another_enterprise_feature").and_return("premium")

      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    it "blocks the alternative action with its own feature key" do
      get :alternative_action

      expect(response)
        .to have_http_status :forbidden
    end

    context "when enterprise token allows both features" do
      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(feature_key).and_return(true)
        allow(EnterpriseToken).to receive(:allows_to?).with("another_enterprise_feature").and_return(true)
      end

      it_behaves_like "succeeds"

      it "allows the alternative action" do
        get :alternative_action

        expect(response)
          .to have_http_status :ok
      end
    end
  end
end
