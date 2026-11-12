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

  context "with the keyword only in an internal journal", with_ee: %i[internal_comments] do
    let(:searchword) { "confidential" }

    before do
      project.update!(enabled_internal_comments: true)
      work_package.add_journal(user: create(:admin), notes: "A #{searchword} remark", internal: true)
      work_package.save!(validate: false)
    end

    it "does not find the work package" do
      expect(subject)
        .to be_empty
    end

    context "when allowed to see internal journals" do
      let(:permissions) { %i[view_work_packages view_internal_comments] }

      it "finds the work package" do
        expect(subject)
          .to eq [work_package]
      end

      context "when internal comments are disabled for the project" do
        before do
          project.update!(enabled_internal_comments: false)
        end

        it "does not find the work package" do
          expect(subject)
            .to be_empty
        end
      end
    end

    context "when allowed to see internal journals in only one of two projects" do
      let(:other_project) { create(:project, enabled_internal_comments: true) }
      let(:other_work_package) { create(:work_package, project: other_project) }

      current_user do
        create(:user, member_with_permissions: { project => %i[view_work_packages view_internal_comments],
                                                 other_project => %i[view_work_packages] })
      end

      before do
        other_work_package.add_journal(user: create(:admin), notes: "Another #{searchword} remark", internal: true)
        other_work_package.save!(validate: false)
      end

      it "finds only the work package of the project with the permission" do
        expect(subject)
          .to eq [work_package]
      end
    end

    context "when being anonymous on a public project", with_settings: { login_required: false } do
      current_user { User.anonymous }

      before do
        project.update!(public: true)
        create(:anonymous_role, permissions: %i[view_work_packages])
      end

      it "does not find the work package" do
        expect(described_class.visible(current_user))
          .to include(work_package)

        expect(subject)
          .to be_empty
      end
    end
  end

  context "with the keyword only in an internal journal and no enterprise token" do
    let(:searchword) { "confidential" }
    let(:permissions) { %i[view_work_packages view_internal_comments] }

    before do
      project.update!(enabled_internal_comments: true)
      work_package.add_journal(user: create(:admin), notes: "A #{searchword} remark", internal: true)
      work_package.save!(validate: false)
    end

    it "does not find the work package" do
      expect(subject)
        .to be_empty
    end
  end
end
