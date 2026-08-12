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

RSpec.describe UsersHelper do
  describe "#render_user_form_hooks" do
    let(:form) { instance_double(Primer::Forms::Builder) }
    let(:user) { build_stubbed(:user) }

    before do
      allow(helper).to receive(:call_hook).and_return("".html_safe)
      allow(OpenProject::Deprecation).to receive(:warn)
      allow(helper).to receive(:fields_for).and_yield(instance_double(TabularFormBuilder))
    end

    it "always calls the new Primer hook" do
      allow(OpenProject::Hook).to receive(:hook_listeners).with(:view_users_form).and_return([])

      helper.render_user_form_hooks(user:, form:)

      expect(helper).to have_received(:call_hook).with(:view_users_primer_form, hash_including(form:))
    end

    context "when no legacy listener is registered" do
      before { allow(OpenProject::Hook).to receive(:hook_listeners).with(:view_users_form).and_return([]) }

      it "does not warn and does not render the legacy hook" do
        helper.render_user_form_hooks(user:, form:)

        expect(OpenProject::Deprecation).not_to have_received(:warn)
        expect(helper).not_to have_received(:fields_for)
      end
    end

    context "when a legacy listener is registered" do
      before { allow(OpenProject::Hook).to receive(:hook_listeners).with(:view_users_form).and_return([instance_double(Object)]) }

      it "logs a deprecation and renders the legacy hook" do
        helper.render_user_form_hooks(user:, form:)

        expect(OpenProject::Deprecation).to have_received(:warn)
        expect(helper).to have_received(:call_hook).with(:view_users_form, hash_including(:form))
      end
    end
  end
end
