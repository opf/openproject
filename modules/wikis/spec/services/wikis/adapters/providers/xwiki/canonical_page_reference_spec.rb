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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::Adapters::Providers::XWiki::CanonicalPageReference do
  describe ".parse" do
    subject { described_class.parse(identifier) }

    context "with a standard identifier" do
      let(:identifier) { "xwiki:Main.WebHome" }

      it { is_expected.to have_attributes(wiki: "xwiki", spaces: ["Main"], page: "WebHome") }
    end

    context "with a nested space identifier" do
      let(:identifier) { "xwiki:MySpace.SubSpace.PageName" }

      it { is_expected.to have_attributes(wiki: "xwiki", spaces: %w[MySpace SubSpace], page: "PageName") }
    end

    context "without a colon separator" do
      let(:identifier) { "Main.WebHome" }

      it { is_expected.to be_nil }
    end

    context "with a blank page path" do
      let(:identifier) { "xwiki:" }

      it { is_expected.to be_nil }
    end

    context "without a space segment" do
      let(:identifier) { "xwiki:WebHome" }

      it { is_expected.to be_nil }
    end
  end

  describe "#rest_path" do
    subject { described_class.parse(identifier).rest_path }

    context "with a single-space identifier" do
      let(:identifier) { "xwiki:Main.WebHome" }

      it { is_expected.to eq("/wikis/xwiki/spaces/Main/pages/WebHome") }
    end

    context "with a nested-space identifier" do
      let(:identifier) { "xwiki:MySpace.SubSpace.PageName" }

      it { is_expected.to eq("/wikis/xwiki/spaces/MySpace/spaces/SubSpace/pages/PageName") }
    end

    context "with special characters in segments" do
      let(:identifier) { "xwiki:My Space.My Page" }

      it { is_expected.to eq("/wikis/xwiki/spaces/My%20Space/pages/My%20Page") }
    end
  end

  describe "#to_s" do
    subject { described_class.parse(identifier).to_s }

    context "with a standard identifier" do
      let(:identifier) { "xwiki:Main.WebHome" }

      it "roundtrips" do
        expect(subject).to eq(identifier)
      end
    end

    context "with a nested space identifier" do
      let(:identifier) { "xwiki:MySpace.SubSpace.PageName" }

      it "roundtrips" do
        expect(subject).to eq(identifier)
      end
    end
  end
end
