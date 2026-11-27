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

RSpec.describe OpenProject::ObjectLinking, type: :helper do
  describe "#primer_link_to_user" do
    subject { helper.primer_link_to_user(user) }

    context "with a regular user" do
      let(:user) { create(:user, firstname: "John", lastname: "Doe") }

      it "renders a link to the user" do
        expect(subject).to have_link("John Doe", href: "/users/#{user.id}")
      end
    end

    context "with nil" do
      let(:user) { nil }

      it "renders without raising" do
        expect { subject }.not_to raise_error
        expect(subject).to have_css("span")
        expect(subject).to have_no_link
      end
    end

    context "with a locked user as an admin" do
      let(:user) { create(:user, firstname: "John", lastname: "Doe", status: :locked) }

      before { login_as create(:admin) }

      it "renders a link to the user" do
        expect(subject).to have_link("John Doe", href: "/users/#{user.id}")
      end
    end

    context "with a locked user as a non-admin" do
      let(:user) { create(:user, firstname: "John", lastname: "Doe", status: :locked) }

      before { login_as create(:user) }

      it "renders the name in a span without a link" do
        expect(subject).to have_css("span", text: "John Doe")
        expect(subject).to have_no_link
      end
    end
  end
end
