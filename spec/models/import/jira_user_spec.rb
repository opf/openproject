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

RSpec.describe Import::JiraUser do
  let(:jira_user) { described_class.new(payload:) }

  describe "#to_op_attributes" do
    subject(:attributes) { jira_user.to_op_attributes }

    context "with a plain display name" do
      let(:payload) { { "displayName" => "Alice Smith", "name" => "asmith", "emailAddress" => "a@example.com" } }

      it "splits first and last name" do
        expect(attributes[:firstname]).to eq("Alice")
        expect(attributes[:lastname]).to eq("Smith")
      end
    end

    context "with non-alphanumeric characters in the display name" do
      let(:payload) { { "displayName" => "Alice [Smith]", "name" => "asmith", "emailAddress" => "a@example.com" } }

      it "strips invalid characters" do
        expect(attributes[:firstname]).to eq("Alice")
        expect(attributes[:lastname]).to eq("Smith")
      end
    end

    context "with special characters not allowed in OP user names" do
      let(:payload) { { "displayName" => "João! Silva", "name" => "jsilva", "emailAddress" => "j@example.com" } }

      it "removes disallowed characters while preserving valid unicode letters" do
        expect(attributes[:firstname]).to eq("João")
        expect(attributes[:lastname]).to eq("Silva")
      end
    end

    context "with leading/trailing whitespace after sanitization" do
      let(:payload) { { "displayName" => "[Alice] Smith", "name" => "asmith", "emailAddress" => "a@example.com" } }

      it "strips surrounding whitespace" do
        expect(attributes[:firstname]).to eq("Alice")
        expect(attributes[:lastname]).to eq("Smith")
      end
    end

    context "with allowed special characters" do
      let(:payload) { { "displayName" => "O'Brien-Smith", "name" => "obrien", "emailAddress" => "o@example.com" } }

      it "preserves allowed special characters" do
        expect(attributes[:firstname]).to eq("O'Brien-Smith")
        expect(attributes[:lastname]).to eq("O'Brien-Smith")
      end
    end

    context "with '🤡' in the display name" do
      let(:payload) { { "displayName" => "🤡 Smith", "name" => "asmith", "emailAddress" => "a@example.com" } }

      it "preserves '#' because it is in Unicode's Emoji property" do
        expect(attributes[:firstname]).to eq("🤡")
        expect(attributes[:lastname]).to eq("Smith")
      end
    end

    context "with '#' in the display name" do
      let(:payload) { { "displayName" => "Alice #Smith", "name" => "asmith", "emailAddress" => "a@example.com" } }

      it "preserves '#' because it is in Unicode's Emoji property" do
        expect(attributes[:firstname]).to eq("Alice")
        expect(attributes[:lastname]).to eq("#Smith")
      end
    end

    context "with '[]' as the display name" do
      let(:payload) { { "displayName" => "[]", "name" => "devil", "emailAddress" => "a@example.com" } }

      it "uses fallbacks" do
        fallback = I18n.t(described_class::FALLBACK_NAME_KEY)
        expect(attributes[:firstname]).to eq(fallback)
        expect(attributes[:lastname]).to eq(fallback)
      end
    end
  end

  describe "#try_to_find_existing_op_users" do
    subject(:result) { jira_user.try_to_find_existing_op_users }

    let(:payload) { { "displayName" => "Test User", "name" => "testuser", "emailAddress" => "test@example.com" } }

    context "when no matching user exists" do
      it "returns an empty relation" do
        expect(result).to be_empty
      end
    end

    context "when a user with matching login exists (case-insensitive)" do
      let!(:existing_user) { create(:user, login: "TestUser", mail: "other@example.com") }

      it "finds the user" do
        expect(result).to contain_exactly(existing_user)
      end
    end

    context "when a user with matching email exists (case-insensitive)" do
      let!(:existing_user) { create(:user, login: "otherlogin", mail: "TEST@EXAMPLE.COM") }

      it "finds the user" do
        expect(result).to contain_exactly(existing_user)
      end
    end

    context "when a user matches both login and email" do
      let!(:existing_user) { create(:user, login: "TESTUSER", mail: "TEST@example.com") }

      it "finds the user once" do
        expect(result).to contain_exactly(existing_user)
      end
    end

    context "when different users match login and email respectively" do
      let!(:user_by_login) { create(:user, login: "TESTUSER", mail: "different@example.com") }
      let!(:user_by_email) { create(:user, login: "differentlogin", mail: "TEST@EXAMPLE.COM") }

      it "finds both users" do
        expect(result).to contain_exactly(user_by_login, user_by_email)
      end
    end

    context "when email is nil in payload" do
      let(:payload) { { "displayName" => "Test User", "name" => "testuser", "emailAddress" => nil } }
      let!(:existing_user) { create(:user, login: "TESTUSER", mail: "any@example.com") }

      it "still finds users by login" do
        expect(result).to contain_exactly(existing_user)
      end
    end

    context "when email separator is used" do
      let(:payload) { { "displayName" => "Test User", "name" => "othername", "emailAddress" => "any@example.com" } }
      let!(:existing_user) { create(:user, login: "testname", mail: "any+test@example.com") }

      it "considers the email to be different and does not find it this user account" do
        expect(result).to be_empty
      end
    end
  end

  describe "#sanitize_name (private)" do
    subject(:jira_user) { described_class.new(payload: {}) }

    def sanitize(name)
      jira_user.send(:sanitize_name, name)
    end

    it "passes through a clean name unchanged" do
      expect(sanitize("Alice Smith")).to eq("Alice Smith")
    end

    it "removes characters not allowed in OP user names" do
      expect(sanitize("Foo!Bar")).to eq("FooBar")
      expect(sanitize("Test[User]")).to eq("TestUser")
      expect(sanitize("Name/With/Slashes")).to eq("NameWithSlashes")
    end

    it "preserves unicode letters and combining marks" do
      expect(sanitize("Ångström")).to eq("Ångström")
      expect(sanitize("Ñoño")).to eq("Ñoño")
    end

    it "preserves allowed punctuation" do
      expect(sanitize("O'Brien-Smith")).to eq("O'Brien-Smith")
      expect(sanitize("user@domain")).to eq("user@domain")
    end

    it "strips leading and trailing whitespace left after removal" do
      expect(sanitize("!Alice!")).to eq("Alice")
      expect(sanitize("[Bob]")).to eq("Bob")
    end

    it "returns an empty string when no valid characters remain" do
      expect(sanitize("!!!")).to eq("")
    end
  end
end
