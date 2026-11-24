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

RSpec.describe Reports::CategoryReport do
  let(:project) { create(:project) }

  subject(:report) { described_class.new(project) }

  describe "#title" do
    context "with the multiple categories feature enabled",
            with_flag: { work_package_multiple_categories: true },
            with_settings: { work_package_multiple_categories: true } do
      it "labels the report with the plural categories attribute" do
        expect(report.title).to eq(WorkPackage.human_attribute_name(:categories))
      end
    end

    context "with the multiple categories feature disabled",
            with_settings: { work_package_multiple_categories: false } do
      it "labels the report with the single category attribute" do
        expect(report.title).to eq(WorkPackage.human_attribute_name(:category))
      end
    end
  end
end
