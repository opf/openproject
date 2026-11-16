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

RSpec.describe ApplicationController, "enforcement of authorization" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user) { create(:user) }

  controller_setup = Module.new do
    extend ActiveSupport::Concern

    included do
      def index
        render plain: "OK"
      end

      private

      def require_admin; end
      def authorize_global; end

      def authorize; end

      def load_and_authorize_in_optional_project; end

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

  shared_examples "is prevented" do |action_name = :index|
    it "fails with a RuntimeError" do
      expect { get action_name }
        .to raise_error RuntimeError
    end
  end

  context "without authorization or authorization forfeiting" do
    controller do
      include controller_setup
    end

    it_behaves_like "is prevented"
  end

  context "with authorization checked with require_admin" do
    controller do
      before_action :require_admin

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked with authorize_global" do
    controller do
      before_action :authorize_global

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked with authorize" do
    controller do
      before_action :authorize

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked with authorize_with_permission" do
    controller do
      include Accounts::Authorization
      include controller_setup

      authorize_with_permission :view_project

      def do_authorize(*)
        true
      end
    end

    it_behaves_like "succeeds"

    it "calls the authorization method" do
      allow(controller).to receive(:do_authorize)

      get :index

      expect(controller).to have_received(:do_authorize).with(:view_project, global: false)
    end
  end

  context "with authorization checked with authorize_with_permission on a single action" do
    controller do
      include Accounts::Authorization
      include controller_setup

      authorize_with_permission :view_project, only: %i[test]

      def test
        render plain: "OK"
      end

      def do_authorize(*)
        true
      end
    end

    before do
      @routes.draw do # rubocop:disable RSpec/InstanceVariable
        get "/anonymous/index"
        get "/anonymous/test"
      end
    end

    it "allows calling test" do
      allow(controller).to receive(:do_authorize)

      get :test

      expect(controller).to have_received(:do_authorize).with(:view_project, global: false)
    end

    it_behaves_like "is prevented", :index
  end

  context "with authorization checked with authorize_with_global_permission" do
    controller do
      include Accounts::Authorization
      include controller_setup

      authorize_with_global_permission :view_project

      def do_authorize(*)
        true
      end
    end

    it "does not load the project and calls global authorization" do
      allow(controller).to receive(:do_authorize)
      allow(Project).to receive(:find)

      get :index, params: { project_id: "1" }

      expect(Project).not_to have_received(:find)
      expect(controller).to have_received(:do_authorize).with(:view_project, global: true)
    end
  end

  context "with authorization checked with load_and_authorize_with_permission_in_project" do
    controller do
      include Accounts::Authorization
      include controller_setup

      load_and_authorize_with_permission_in_project :view_project

      def do_authorize(*)
        true
      end
    end

    it "loads the project and calls project authorization" do
      allow(controller).to receive(:do_authorize)
      allow(Project).to receive(:find)

      get :index, params: { project_id: "1" }

      expect(Project).to have_received(:find).with("1")
      expect(controller).to have_received(:do_authorize).with(:view_project, global: false)
    end

    it "renders 404 if project_id is missing" do
      allow(controller).to receive(:do_authorize)

      get :index

      expect(response).to have_http_status :not_found
      expect(controller).not_to have_received(:do_authorize)
    end
  end

  context "with authorization checked with load_and_authorize_in_optional_project" do
    controller do
      before_action :load_and_authorize_in_optional_project

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked via prepend_before_action" do
    controller do
      prepend_before_action :authorize

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked via append_before_action" do
    controller do
      append_before_action :authorize

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with another before action specified" do
    controller do
      before_action :other_before_action

      include controller_setup
    end

    it_behaves_like "is prevented"
  end

  context "with authorization check in the superclass" do
    controller(described_class) do
      before_action :require_admin
    end

    controller(controller_class) do
      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "when forfeiting authorization checks on this specific action" do
    controller do
      no_authorization_required! :index

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "when stating that authorization has been checked in the superclass" do
    controller(described_class) do
      authorization_checked! :index
    end

    controller(controller_class) do
      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "when forfeiting authorization checks in the superclass" do
    controller(described_class) do
      no_authorization_required! :index
    end

    controller(controller_class) do
      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "when forfeiting authorization checks on another action" do
    controller do
      no_authorization_required! :some_other_action

      include controller_setup
    end

    it_behaves_like "is prevented"
  end

  context "with authorization checked on another action with only" do
    controller do
      before_action :require_admin, only: %i[some_other_action]

      include controller_setup
    end

    it_behaves_like "is prevented"
  end

  context "with authorization checked on the action with only" do
    controller do
      before_action :require_admin, only: %i[index]

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked on all but this action with except" do
    controller do
      before_action :require_admin, except: %i[index]

      include controller_setup
    end

    it_behaves_like "is prevented"
  end

  context "with authorization checked on all but another action with except" do
    controller do
      before_action :require_admin, except: %i[another_action]

      def another_action; end

      include controller_setup
    end

    it_behaves_like "succeeds"
  end

  context "with authorization checked in a sibling class" do
    # Superclass
    controller do
      include controller_setup
    end

    anonymous_superclass = controller_class

    # Sibling class
    controller(anonymous_superclass) do
      before_action :require_admin
    end

    # actually tested class
    controller(anonymous_superclass) do
      # Nothing extra
    end

    it_behaves_like "is prevented"
  end

  context "with authorization checked by a number of different actions" do
    controller do
      before_action :require_admin, except: %i[index]
      before_action :authorize, only: %i[index]

      include controller_setup
    end

    it_behaves_like "succeeds"
  end
end
