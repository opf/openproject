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
