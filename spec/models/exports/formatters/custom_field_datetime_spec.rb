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

RSpec.describe Exports::Formatters::CustomField, "with a datetime custom field",
               with_settings: { date_format: "%Y-%m-%d", time_format: "%H:%M" } do
  let(:custom_field) { build_stubbed(:wp_custom_field, :datetime) }
  let(:custom_value) { CustomValue.new(custom_field:, value:) }
  let(:value) { "2026-10-01T12:30:00Z" }
  let(:work_package) do
    build_stubbed(:work_package).tap do |wp|
      allow(wp).to receive(:custom_value_for).with(custom_field).and_return(custom_value)
    end
  end

  current_user { build_stubbed(:user, preferences: { time_zone: "Europe/Berlin" }) }

  shared_examples "formats the value in the user's time zone" do
    it "exports the date and time in the user's time zone" do
      expect(formatter.format_for_export(work_package, custom_field)).to eq("2026-10-01 14:30")
    end

    context "without a value" do
      let(:value) { nil }

      it "exports an empty string" do
        expect(formatter.format_for_export(work_package, custom_field)).to eq("")
      end
    end
  end

  context "for CSV and XLS exports" do
    subject(:formatter) { described_class.new("cf_#{custom_field.id}") }

    it_behaves_like "formats the value in the user's time zone"
  end

  context "for PDF exports" do
    subject(:formatter) { Exports::Formatters::CustomFieldPdf.new("cf_#{custom_field.id}") }

    it_behaves_like "formats the value in the user's time zone"
  end
end
