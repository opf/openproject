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

RSpec.describe ApplicationController, "enforcement of authorization" do # rubocop:disable RSpec/RSpec/SpecFilePathFormat
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

  shared_examples "succeeds" do
    it "succeeds" do
      get :index

      expect(response)
        .to have_http_status :ok
    end
  end

  shared_examples "is prevented" do
    it "fails with a RuntimeError" do
      expect { get :index }
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
