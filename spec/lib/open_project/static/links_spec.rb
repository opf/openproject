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

RSpec.describe OpenProject::Static::Links do
  describe ".url_for" do
    subject { described_class.url_for(*args) }

    let(:args) { %i[enterprise_features board_view] }
    let(:locale_param) { "?go_to_locale=#{I18n.locale}" }

    it "resolves the URL stored in the href with a locale" do
      expect(subject)
        .to eq("https://www.openproject.org/docs/user-guide/agile-boards/#{locale_param}#action-boards-enterprise-add-on")
    end

    context "with german locale" do
      before do
        I18n.locale = :de
      end

      it "resolves the URL stored in the href with a locale" do
        expect(subject)
          .to eq("https://www.openproject.org/docs/user-guide/agile-boards/#{locale_param}#action-boards-enterprise-add-on")
      end
    end

    context "with docs URLs" do
      let(:args) { %i[sysadmin_docs oidc] }

      it "adds locale parameter to docs URLs" do
        expect(subject)
          .to eq("https://www.openproject.org/docs/system-admin-guide/authentication/openid-providers/#{locale_param}")
      end
    end

    context "with website URL" do
      let(:args) { %i[website] }

      it "adds locale parameter to website URL" do
        expect(subject).to eq("https://www.openproject.org?go_to_locale=en")
      end
    end

    context "with other URLs" do
      let(:args) { %i[github] }

      it "does not add a parameter" do
        expect(subject).to eq("https://github.com/opf/openproject")
        expect(subject).not_to include("go_to_locale=")
      end
    end

    context "with additional URL parameters" do
      let(:args) { %i[website] }

      it "adds custom URL parameters" do
        result = described_class.url_for(*args, url_params: { utm_source: "test", utm_medium: "spec" })
        expect(result).to include("utm_source=test")
        expect(result).to include("utm_medium=spec")
      end
    end

    context "with non-existent path" do
      let(:args) { %i[non_existent_key] }

      it "returns nil for non-existent paths" do
        expect(subject).to be_nil
      end
    end

    context "with localize_url disabled" do
      let(:args) { %i[enterprise_features board_view] }

      it "does not add locale parameter when localize_url is false" do
        result = described_class.url_for(*args, localize_url: false)
        expect(result).not_to include("go_to_locale=")
        expect(result).to eq("https://www.openproject.org/docs/user-guide/agile-boards/#action-boards-enterprise-add-on")
      end
    end
  end

  describe ".label_for" do
    subject { described_class.label_for(*args) }

    let(:args) { %i[website] }

    it "returns the translated label for the given path" do
      expect(subject).to eq(I18n.t("label_openproject_website"))
    end

    context "with single key" do
      let(:args) { %i[shortcuts] }

      it "returns the translated label for a single key" do
        expect(subject).to eq(I18n.t("homescreen.links.shortcuts"))
      end
    end

    context "with non-existent path" do
      let(:args) { %i[non_existent_key] }

      it "returns nil for non-existent paths" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".cache_key" do
    subject { described_class.cache_key }

    it "returns a cache key based on the links" do
      expect(subject).to be_a(String)
      expect(subject).not_to be_empty
    end

    it "returns the same key for multiple calls" do
      first_call = described_class.cache_key
      second_call = described_class.cache_key
      expect(first_call).to eq(second_call)
    end
  end

  describe ".has?" do
    subject { described_class.has?(key) }

    context "with existing key" do
      let(:key) { :website }

      it "returns true for existing keys" do
        expect(subject).to be true
      end
    end

    context "with non-existing key" do
      let(:key) { :non_existent_key }

      it "returns false for non-existing keys" do
        expect(subject).to be false
      end
    end
  end

  describe ".website_url" do
    subject { described_class.website_url }

    it "returns the website URL" do
      expect(subject).to eq("https://www.openproject.org")
    end
  end

  describe ".website_link?" do
    subject { described_class.website_link?(url) }

    context "with docs URLs" do
      let(:url) { "https://www.openproject.org/docs/user-guide/agile-boards/" }

      it "returns true for URLs that start with the docs base URL" do
        expect(subject).to be true
      end
    end

    context "with non-docs URLs" do
      let(:url) { "https://foo.example.com" }

      it "returns false for URLs that do not start with the docs base URL" do
        expect(subject).to be false
      end
    end

    context "with nil URL" do
      let(:url) { nil }

      it "returns false for nil URLs" do
        expect(subject).to be_falsy
      end
    end
  end

  describe ".help_link_overridden?" do
    subject { described_class.help_link_overridden? }

    context "when help link is not overridden" do
      before do
        allow(OpenProject::Configuration).to receive(:force_help_link).and_return(nil)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when help link is overridden" do
      before do
        allow(OpenProject::Configuration).to receive(:force_help_link).and_return("https://custom.help.com")
      end

      it "returns true" do
        expect(subject).to be true
      end
    end
  end

  describe ".help_link" do
    subject { described_class.help_link }

    context "when help link is not overridden" do
      before do
        allow(OpenProject::Configuration).to receive(:force_help_link).and_return(nil)
      end

      it "returns the default user guides link" do
        expect(subject).to eq("https://www.openproject.org/docs/user-guide/")
      end
    end

    context "when help link is overridden" do
      before do
        allow(OpenProject::Configuration).to receive(:force_help_link).and_return("https://custom.help.com")
      end

      it "returns the overridden help link" do
        expect(subject).to eq("https://custom.help.com")
      end
    end
  end
end
