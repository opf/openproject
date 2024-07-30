#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe MailHandler::UserCreator do
  describe ".new_user_from_attributes" do
    context "with sufficient information" do
      # [address, name] => [login, firstname, lastname]
      {
        ["jsmith@example.net", nil] => %w[jsmith@example.net jsmith -],
        %w[jsmith@example.net John] => %w[jsmith@example.net John -],
        ["jsmith@example.net", "John Smith"] => %w[jsmith@example.net John Smith],
        ["jsmith@example.net", "John Paul Smith"] => ["jsmith@example.net", "John", "Paul Smith"],
        ["jsmith@example.net", "AVeryLongFirstnameThatNoLongerExceedsTheMaximumLength Smith"] =>
          %w[jsmith@example.net AVeryLongFirstnameThatNoLongerExceedsTheMaximumLength Smith],
        ["jsmith@example.net", "John AVeryLongLastnameThatNoLongerExceedsTheMaximumLength"] =>
          %w[jsmith@example.net John AVeryLongLastnameThatNoLongerExceedsTheMaximumLength]
      }.each do |(provided_mail, provided_fullname), (expected_login, expected_firstname, expected_lastname)|
        it "returns a valid user" do
          user = described_class.send(:new_user_from_attributes, provided_mail, provided_fullname)

          expect(user)
            .to be_valid
          expect(user.mail)
            .to eq provided_mail
          expect(user.login)
            .to eq expected_login
          expect(user.firstname)
            .to eq expected_firstname
          expect(user.lastname)
            .to eq expected_lastname
        end
      end
    end

    context "with min password length",
            with_legacy_settings: { password_min_length: 15 } do
      it "respects minimum password length" do
        user = described_class.send(:new_user_from_attributes, "jsmith@example.net")

        expect(user)
          .to be_valid

        expect(user.password.length)
          .to be 15
      end
    end

    context "when the attributes are invalid",
            with_legacy_settings: { password_min_length: 15 } do
      it "respects minimum password length" do
        user = described_class.send(:new_user_from_attributes, "foo&bar@example.net")

        expect(user)
          .to be_valid

        expect(user.login)
          .to match /^user[a-f0-9]+$/

        expect(user.mail)
          .to eq "foo&bar@example.net"
      end
    end
  end
end
