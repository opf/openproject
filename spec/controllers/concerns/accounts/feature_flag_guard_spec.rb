# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ApplicationController, "enforcement of feature flag guards" do # rubocop:disable RSpec/SpecFilePathFormat
  # rubocop:disable RSpec/BeforeAfterAll
  before(:context) do
    %i[fake_feature_flag_one fake_feature_flag_two].each do |flag|
      OpenProject::FeatureDecisions.define_singleton_method(:"#{flag}_active?") { false }
    end
  end

  after(:context) do
    %i[fake_feature_flag_one fake_feature_flag_two].each do |flag|
      OpenProject::FeatureDecisions.singleton_class.send(:remove_method, :"#{flag}_active?")
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll

  shared_let(:user) { create(:user) }

  controller_setup = Module.new do
    extend ActiveSupport::Concern

    included do
      # These calls prevent the RuntimeError about authorization checks being required
      # They tell the controller that authorization has been handled separately
      # In real usage, the feature flag guard itself would be the authorization check
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
    it "returns 404 not found" do
      get action_name

      expect(response)
        .to have_http_status :not_found
    end
  end

  shared_examples "redirects" do |action_name = :index|
    it "redirects" do
      get action_name

      expect(response)
        .to have_http_status :redirect
    end
  end

  context "with feature check using guard_feature_flag", with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      guard_feature_flag :fake_feature_flag_one
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    context "when the feature flag is active", with_flag: { fake_feature_flag_one: true } do
      it_behaves_like "succeeds"
    end
  end

  context "with feature check using guard_feature_flag on a single action",
          with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      guard_feature_flag :fake_feature_flag_one, only: %i[index]

      # Mark alternative_action as having authorization checked separately
      # since it's not guarded by the feature flag
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

  context "with feature check using guard_feature_flag except for an action",
          with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      guard_feature_flag :fake_feature_flag_one, except: %i[alternative_action]

      # Mark alternative_action as having authorization checked separately
      # since it's not guarded by the feature flag
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

  context "with feature check using guard_feature_flag with a custom block",
          with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      guard_feature_flag :fake_feature_flag_one do
        redirect_to "/custom/path"
      end

      # No need for explicit authorization_checked! calls here since guard_feature_flag
      # should implicitly mark actions as authorized
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "redirects"
  end

  context "with feature check in the superclass", with_flag: { fake_feature_flag_one: false } do
    controller(described_class) do
      include Accounts::FeatureFlagGuard

      guard_feature_flag :fake_feature_flag_one
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

    context "when the feature flag is active", with_flag: { fake_feature_flag_one: true } do
      it_behaves_like "succeeds"
    end
  end

  context "with feature check via prepend_before_action", with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      prepend_before_action { perform_feature_flag_guard("fake_feature_flag_one") }

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

    context "when the feature flag is active", with_flag: { fake_feature_flag_one: true } do
      it_behaves_like "succeeds"
    end
  end

  context "with feature check via append_before_action", with_flag: { fake_feature_flag_one: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      append_before_action { perform_feature_flag_guard("fake_feature_flag_one") }

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

    context "when the feature flag is active", with_flag: { fake_feature_flag_one: true } do
      it_behaves_like "succeeds"
    end
  end

  context "with multiple feature checks", with_flag: { fake_feature_flag_one: false, fake_feature_flag_two: false } do
    controller do
      include Accounts::FeatureFlagGuard
      include controller_setup

      guard_feature_flag :fake_feature_flag_one, only: %i[index]
      guard_feature_flag :fake_feature_flag_two, only: %i[alternative_action]
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/alternative_action"
      end
    end

    it_behaves_like "is blocked"

    it "blocks the alternative action with its own feature flag" do
      get :alternative_action

      expect(response)
        .to have_http_status :not_found
    end

    context "when both feature flags are active",
            with_flag: { fake_feature_flag_one: true, fake_feature_flag_two: true } do
      it_behaves_like "succeeds"

      it "allows the alternative action" do
        get :alternative_action

        expect(response)
          .to have_http_status :ok
      end
    end
  end
end
