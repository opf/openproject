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

RSpec.describe Exports::Concerns::CSVFormulaSanitization do
  subject(:sanitize) { described_class.sanitize(value) }

  context "when escaping is enabled (default)", with_settings: { csv_escape_formulas: true } do
    context "with formula-leading values" do
      [
        "=1+1",
        '=HYPERLINK("https://example.com","x")',
        "=WEBSERVICE(\"http://attacker.example\")",
        "@SUM(A1:A2)",
        "+1+1",
        "-1+cmd|' /C calc'!A0",
        "\t=1+1",
        "\r=1+1"
      ].each do |dangerous|
        context "with #{dangerous.inspect}" do
          let(:value) { dangerous }

          it "prepends a single quote" do
            expect(sanitize).to eq("'#{dangerous}")
          end
        end
      end
    end

    context "with plain numbers and dates (numeric guard)" do
      ["-5.00", "+5.00", "-1234.56", "-1.234,56 €", "2026-05-31", "0", "42"].each do |benign|
        context "with #{benign.inspect}" do
          let(:value) { benign }

          it "leaves the value untouched" do
            expect(sanitize).to eq(benign)
          end
        end
      end
    end

    context "with ordinary text" do
      let(:value) { "Implement login screen" }

      it "leaves the value untouched" do
        expect(sanitize).to eq("Implement login screen")
      end
    end

    context "with a blank value" do
      let(:value) { "" }

      it "leaves the value untouched" do
        expect(sanitize).to eq("")
      end
    end

    context "with a non-string value" do
      let(:value) { 42 }

      it "returns its string form untouched" do
        expect(sanitize).to eq("42")
      end
    end
  end

  context "when escaping is disabled", with_settings: { csv_escape_formulas: false } do
    let(:value) { "=1+1" }

    it "leaves dangerous values untouched" do
      expect(sanitize).to eq("=1+1")
    end
  end
end
