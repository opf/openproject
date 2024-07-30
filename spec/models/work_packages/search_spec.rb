# --copyright
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
# ++

require "spec_helper"

RSpec.describe WorkPackage, "search" do
  shared_let(:description_searchword) { "descKeyword" }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) do
    create(:work_package, project:, description: "The description with the #{description_searchword}.")
  end

  let(:permissions) { [:view_work_packages] }
  let(:searchword) { "keyword" }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  subject { described_class.search(searchword).first }

  context "with the keyword being in the description" do
    let(:searchword) { description_searchword }

    it "finds the work package" do
      expect(subject)
        .to eq [work_package]
    end

    context "when lacking the permissions to see the work package" do
      let(:permissions) { [] }

      it "does not find the work package" do
        expect(subject)
          .to be_empty
      end
    end
  end

  context "with multiple hits in journals", with_settings: { journal_aggregation_time_minutes: 0 } do
    before do
      # Adding two journals with the keyword in it
      work_package.journals.first.update_column(:notes, "A note with the #{searchword} in it.")

      work_package.journal_notes = "The #{searchword} is in here"
      work_package.save
    end

    it "finds the work package" do
      expect(subject)
        .to eq [work_package]
    end
  end
end
