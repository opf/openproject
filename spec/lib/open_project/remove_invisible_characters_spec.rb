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

RSpec.describe OpenProject::RemoveInvisibleCharacters do
  subject(:call) { described_class.call(value) }

  context "with a clean string" do
    let(:value) { "Hello World" }

    it { is_expected.to eq("Hello World") }
  end

  context "with newline and tab characters" do
    let(:value) { "Hello\n\tWorld\r\n" }

    it { is_expected.to eq("HelloWorld") }
  end

  context "with null byte" do
    let(:value) { "Hello\x00World" }

    it { is_expected.to eq("HelloWorld") }
  end

  context "with escape and delete characters" do
    let(:value) { "Hello\x1B\x7FWorld" }

    it { is_expected.to eq("HelloWorld") }
  end

  context "with a mix of control characters" do
    let(:value) { "\x01He\x02llo\x03 \x04Wo\x05rld\x06" }

    it { is_expected.to eq("Hello World") }
  end

  context "with zero-width space (U+200B)" do
    let(:value) { "Hello\u200BWorld" }

    it { is_expected.to eq("HelloWorld") }
  end

  context "with multiple zero-width characters" do
    let(:value) { "Hello\u200B\u200C\u200D\uFEFF\u2060World" }

    it { is_expected.to eq("HelloWorld") }
  end

  context "with Unicode characters (preserved)" do
    let(:value) { "Héllo Wörld 日本語" }

    it { is_expected.to eq("Héllo Wörld 日本語") }
  end

  context "with spaces and quotes (preserved)" do
    let(:value) { %{It's a "test" value} }

    it { is_expected.to eq(%{It's a "test" value}) }
  end

  context "with a non-string value" do
    let(:value) { 42 }

    it { is_expected.to eq(42) }
  end

  context "with nil" do
    let(:value) { nil }

    it { is_expected.to be_nil }
  end
end
