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

RSpec.describe "query export settings" do # rubocop:disable RSpec/DescribeClass
  let(:query) { create(:query) }

  describe "export_settings_for" do
    it "creates a new export setting for the given format" do
      setting = query.export_settings_for("csv")

      expect(setting).to be_a_new_record
    end

    context "with an existing export setting" do
      let!(:export_setting) { ExportSetting.create(query_id: query.id, settings: { some_key: :some_value }, format: "xls") }

      it "is returned" do
        setting = query.export_settings_for("xls")

        expect(setting).to be_persisted
        expect(setting.settings).to eq({ some_key: "some_value" })
      end

      it "is not returned for a different format" do
        setting = query.export_settings_for("pdf_report")

        expect(setting).to be_a_new_record
      end
    end
  end
end
