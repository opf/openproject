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

RSpec.describe OpenProject::StrikezoneFrank::Hooks do
  let(:listener) { described_class.instance }
  let(:controller) { instance_double(ApplicationController) }
  let(:request) { instance_double(ActionDispatch::Request, format: Mime[:html]) }

  before do
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:append_content_security_policy_directives)
  end

  describe "#view_layouts_base_html_head" do
    it "renders the Strikezone logo override" do
      hook_caller = instance_double(ApplicationController)
      allow(hook_caller).to receive(:render).and_return("strikezone-logo-css")

      expect(listener.view_layouts_base_html_head(hook_caller:)).to eq("strikezone-logo-css")
      expect(hook_caller).to have_received(:render)
        .with(partial: "strikezone_frank/hooks/logo")
    end
  end

  describe "#application_controller_before_action" do
    context "when the user is logged in" do
      current_user { create(:user) }

      it "appends the Frank origin to frame-src" do
        listener.application_controller_before_action(controller:)

        expect(controller).to have_received(:append_content_security_policy_directives)
          .with(frame_src: ["http://localhost:3001"])
      end
    end

    context "when anonymous and login is required" do
      current_user { User.anonymous }

      it "does not change CSP" do
        allow(Setting).to receive(:login_required?).and_return(true)

        listener.application_controller_before_action(controller:)

        expect(controller).not_to have_received(:append_content_security_policy_directives)
      end
    end
  end
end
