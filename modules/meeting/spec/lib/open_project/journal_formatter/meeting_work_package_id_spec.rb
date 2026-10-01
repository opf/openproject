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

RSpec.describe OpenProject::JournalFormatter::MeetingWorkPackageId do
  let(:instance) { described_class.new(build_stubbed(:journal)) }

  let(:project) { create(:project) }
  let(:old_work_package) { create(:work_package, project:, subject: "Old task") }
  let(:new_work_package) { create(:work_package, project:, subject: "New task") }

  describe "#render" do
    context "when both work packages are visible" do
      before do
        allow(WorkPackage).to receive(:visible).and_return(WorkPackage.where(id: [old_work_package.id, new_work_package.id]))
      end

      it "renders work package names in HTML mode" do
        result = instance.render("work_package_id", [old_work_package.id, new_work_package.id], html: true)

        expect(result).to include("Old task")
        expect(result).to include("New task")
      end

      it "renders work package names in plain text mode" do
        result = instance.render("work_package_id", [old_work_package.id, new_work_package.id], html: false)

        expect(result).to include("Old task")
        expect(result).to include("New task")
      end
    end

    context "when work packages are not visible" do
      before do
        allow(WorkPackage).to receive(:visible).and_return(WorkPackage.none)
      end

      it "renders undisclosed work package text with the ID" do
        result = instance.render("work_package_id", [old_work_package.id, new_work_package.id], html: true)

        expect(result).to include(old_work_package.id.to_s)
        expect(result).to include(new_work_package.id.to_s)
        expect(result).not_to include("Old task")
        expect(result).not_to include("New task")
      end
    end

    context "when work package names contain HTML" do
      let(:old_work_package) { create(:work_package, project:, subject: "Safe task") }
      let(:new_work_package) { create(:work_package, project:, subject: "<img src=x onerror=alert(1)>") }

      before do
        allow(WorkPackage).to receive(:visible).and_return(WorkPackage.where(id: [old_work_package.id, new_work_package.id]))
      end

      it "escapes HTML in work package names" do
        result = instance.render("work_package_id", [old_work_package.id, new_work_package.id], html: true)

        expect(result).not_to include("<img")
        expect(result).to include("&lt;img src=x onerror=alert(1)&gt;")
      end

      it "also escapes in plain text mode since h() is applied unconditionally" do
        result = instance.render("work_package_id", [old_work_package.id, new_work_package.id], html: false)

        expect(result).not_to include("<img")
        expect(result).to include("&lt;img src=x onerror=alert(1)&gt;")
      end
    end
  end
end
