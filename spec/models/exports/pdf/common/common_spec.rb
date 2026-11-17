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

RSpec.describe Exports::PDF::Common::Common do
  let(:exporter) do
    Class.new do
      include Exports::PDF::Common::Common

      attr_reader :options

      def initialize(options)
        @options = options
      end

      public :hyphenation_language
    end.new(options)
  end

  describe "#hyphenation_language" do
    context "with hyphenation enabled and a supported language" do
      let(:options) { { hyphenation: "1", hyphenation_language: "de" } }

      it "returns the language" do
        expect(exporter.hyphenation_language).to eq("de")
      end
    end

    context "with hyphenation disabled" do
      let(:options) { { hyphenation: "0", hyphenation_language: "de" } }

      it "returns nil" do
        expect(exporter.hyphenation_language).to be_nil
      end
    end

    context "with hyphenation enabled and no language" do
      let(:options) { { hyphenation: "1", hyphenation_language: "" } }

      it "returns nil" do
        expect(exporter.hyphenation_language).to be_nil
      end
    end

    context "with hyphenation enabled and an unsupported language" do
      %w[en_us xx ../../hyphen].each do |language|
        context "when the language is #{language.inspect}" do
          let(:options) { { hyphenation: "1", hyphenation_language: language } }

          it "returns nil" do
            expect(exporter.hyphenation_language).to be_nil
          end
        end
      end
    end

    context "with hyphenation enabled and a non-string language" do
      let(:options) { { hyphenation: "1", hyphenation_language: ["de"] } }

      it "returns nil" do
        expect(exporter.hyphenation_language).to be_nil
      end
    end
  end
end
