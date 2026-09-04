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

RSpec.describe Wikis::Adapters::Results::PageSearchTreeNode do
  describe "#key" do
    subject { described_class.new(identifier: "42", type: :page, name: "A page").key }

    it "consists of the node's type and identifier" do
      expect(subject).to eq(described_class::NodeKey.new(type: :page, identifier: "42"))
      expect(subject.to_s).to eq("page:42")
    end
  end

  describe described_class::NodeKey do
    describe ".parse" do
      subject { described_class.parse(string) }

      let(:string) { "page:42" }

      it { is_expected.to eq(described_class.new(type: :page, identifier: "42")) }

      context "when the key refers to a wiki" do
        let(:string) { "wiki:7" }

        it { is_expected.to eq(described_class.new(type: :wiki, identifier: "7")) }
      end

      context "when the opaque identifier contains colons itself" do
        let(:string) { "page:xwiki:VCR.Incredible space.WebHome" }

        it "only splits off the type" do
          expect(subject).to eq(described_class.new(type: :page, identifier: "xwiki:VCR.Incredible space.WebHome"))
        end
      end

      context "when there is no identifier" do
        let(:string) { "page" }

        it { is_expected.to be_nil }
      end

      context "when there is no type" do
        let(:string) { ":42" }

        it { is_expected.to be_nil }
      end

      context "when the key is nil" do
        let(:string) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
