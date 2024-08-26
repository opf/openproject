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
require_module_spec_helper

# These specs mainly check that error messages from a sub-service
# (about unsafe hosts with HTTP protocol) are passed to the main form.
RSpec.describe OpenProject::Storages::AppendStoragesHostsToCspHook do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  let(:storage) { create(:nextcloud_storage) }
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:controller) { instance_double(ApplicationController) }

  before do
    storage
    project_storage

    allow(controller).to receive(:append_content_security_policy_directives)
  end

  def trigger_application_controller_before_action_hook
    hook_listener = described_class.instance
    hook_listener.application_controller_before_action(controller:)
  end

  shared_examples "content security policy directives" do
    it "adds CSP connect_src directives" do
      trigger_application_controller_before_action_hook

      expect(controller).to have_received(:append_content_security_policy_directives)
                              .with(connect_src: [storage.host.chomp("/")])
    end
  end

  shared_examples "does not change CSP" do
    it "does not change CSP directives" do
      trigger_application_controller_before_action_hook

      expect(controller).not_to have_received(:append_content_security_policy_directives)
    end
  end

  context "with a project with an active Nextcloud storage" do
    context "when current user is an admin without being a member of any project" do
      current_user { admin }

      include_examples "content security policy directives"
    end

    context "when current user is a member of the project with permission to manage file links" do
      current_user { create(:user, member_with_permissions: { project => %i[manage_file_links] }) }

      include_examples "content security policy directives"
    end

    context "when current user is a member of the project without permission to manage file links" do
      current_user { create(:user, member_with_permissions: { project => [] }) }

      it "does not add CSP connect_src directive" do
        trigger_application_controller_before_action_hook

        expect(controller).not_to have_received(:append_content_security_policy_directives)
                                    .with(connect_src: [storage.host.chomp("/")])
      end
    end

    context "when the project is archived" do
      current_user { admin }

      before do
        project.update(active: false)
      end

      it "does not add CSP connect_src directive" do
        trigger_application_controller_before_action_hook

        expect(controller).not_to have_received(:append_content_security_policy_directives)
                                    .with(connect_src: [storage.host.chomp("/")])
      end
    end
  end

  context "with a project without an active storage" do
    current_user { admin }
    let(:project_storage) { nil }

    include_examples "does not change CSP"
  end

  context "with a project without any storages configured" do
    current_user { admin }
    let(:project_storage) { nil }
    let(:storage) { nil }

    include_examples "does not change CSP"
  end

  context "with an active Nextcloud storage having a host with a non-standard port" do
    let(:storage) { create(:nextcloud_storage, host: "http://somehost.com:8080/") }

    current_user { admin }

    it "adds the port to the CSP directive" do
      trigger_application_controller_before_action_hook

      expect(controller).to have_received(:append_content_security_policy_directives) do |args|
        expect(args).to eq(connect_src: ["http://somehost.com:8080"])
      end
    end
  end

  context "with an active Nextcloud storage having a host with a path" do
    let(:storage) { create(:nextcloud_storage, host: "https://my.server.com/nextcloud/") }

    current_user { admin }

    it "removes the path from the host for the CSP directive" do
      trigger_application_controller_before_action_hook

      expect(controller).to have_received(:append_content_security_policy_directives) do |args|
        expect(args).to eq(connect_src: ["https://my.server.com"])
      end
    end
  end
end
