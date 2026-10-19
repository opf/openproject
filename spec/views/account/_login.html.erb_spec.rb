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

RSpec.describe "account/_login" do
  subject { render partial: "account/login" }

  context "with self registration enabled" do
    before do
      allow(Setting).to receive(:self_registration)
        .and_return(Setting::SelfRegistration.value(key: :activation_by_email))
      subject
    end

    it "renders the registration section" do
      expect(rendered).to have_link(I18n.t(:label_register), href: account_register_path)
    end
  end

  context "with self registration enabled but password login disabled" do
    before do
      allow(Setting).to receive_messages(
        password_login: "none",
        self_registration: Setting::SelfRegistration.value(key: :activation_by_email)
      )
      subject
    end

    it "does not render the registration section, as registering is not possible" do
      expect(rendered).to have_no_css(".account-prompt")
    end
  end
end
