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

RSpec.describe Reports::VersionReport do
  let(:project) { create(:project) }

  subject(:report) { described_class.new(project) }

  describe "#title" do
    context "with the multiple versions feature enabled",
            with_settings: { work_package_multiple_versions: true } do
      it "labels the report with the singular target version attribute" do
        expect(report.title).to eq(WorkPackage.human_attribute_name(:target_version))
      end
    end

    context "with the multiple versions feature disabled",
            with_settings: { work_package_multiple_versions: false } do
      it "labels the report as the deprecated single version attribute" do
        expect(report.title).to eq(WorkPackage.human_attribute_name(:version))
      end
    end
  end
end
