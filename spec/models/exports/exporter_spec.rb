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

require "rails_helper"

RSpec.describe Exports::Exporter do
  let(:exporter) { described_class.new(nil) }

  context "with #sane_filename" do
    it "normalizes and replaces separators with underscores" do
      expect(exporter.sane_filename("two  words.ext")).to eq("two_words.ext")
    end

    it "removes symbols that may cause problems with popular filesystem" do
      expect(exporter.sane_filename("invalid // , : \\ removed.ext")).to eq("invalid_removed.ext")
    end

    it "uses locale aware transliteration of e.g. umlauts" do
      expect(exporter.sane_filename("ä ö ü ß ẞ.ext")).to eq("a_o_u_ss_SS.ext")

      I18n.with_locale(:de) do
        expect(exporter.sane_filename("ä ö ü ß ẞ.ext")).to eq("ae_oe_ue_ss_SS.ext")
      end

      I18n.with_locale(:uk) do
        expect(exporter.sane_filename("Київ.ext")).to eq("Kyiv.ext")
      end
    end
  end

  context "with #formatter_for" do
    let(:exporter_class) { Class.new(described_class) { self.model = WorkPackage } }
    let(:exporter) { exporter_class.new(nil) }

    it "hands out one instance per attribute and export format" do
      formatter = exporter.send(:formatter_for, :start_date, :xls)

      expect(exporter.send(:formatter_for, :start_date, :xls)).to be(formatter)
      expect(exporter.send(:formatter_for, :due_date, :xls)).not_to be(formatter)
      expect(exporter.send(:formatter_for, :start_date, :csv)).not_to be(formatter)
    end

    it "keeps the cache to itself" do
      formatter = exporter.send(:formatter_for, :start_date, :xls)

      expect(exporter_class.new(nil).send(:formatter_for, :start_date, :xls)).not_to be(formatter)
    end

    it "formats in the exporter's time zone, not the one the thread happens to carry" do
      exporting_user = build_stubbed(:user, preferences: { time_zone: "Asia/Tokyo" })
      allow(User).to receive(:current).and_return(build_stubbed(:user, preferences: { time_zone: "Europe/Berlin" }))

      formatted = exporter_class.new(nil, current_user: exporting_user)
                               .send(:format_attribute, build_stubbed(:work_package), :created_at, :xls)

      expect(formatted.time_zone).to eq(ActiveSupport::TimeZone["Asia/Tokyo"])
    end

    it "formats every record through that one instance, so a formatter may not memoize a record" do
      first = build_stubbed(:work_package, start_date: Date.new(2026, 8, 24))
      second = build_stubbed(:work_package, start_date: Date.new(2026, 9, 1))

      expect(exporter.send(:format_attribute, first, :start_date, :xls)).to eq(Date.new(2026, 8, 24))
      expect(exporter.send(:format_attribute, second, :start_date, :xls)).to eq(Date.new(2026, 9, 1))
    end
  end
end
