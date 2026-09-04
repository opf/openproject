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

RSpec.describe "Work packages bulk edit: sprint and backlog bucket", :skip_csrf, type: :rails_request do
  let!(:sprint) { create(:sprint, project:) }
  let!(:bucket) { create(:backlog_bucket, project:) }

  let(:work_package1) { create(:work_package, project:) }
  let(:work_package2) { create(:work_package, project:) }

  let(:project) { create(:project, enabled_module_names: enabled_modules) }
  let(:enabled_modules) { %i[backlogs work_package_tracking] }
  let(:permissions) do
    %i[view_work_packages edit_work_packages view_sprints manage_sprint_items]
  end
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  describe "GET edit" do
    before { get edit_work_packages_bulk_path(ids: [work_package1.id, work_package2.id]) }

    it "displays the sprint and backlog bucket selects" do
      expect(response.body).to have_select("Sprint", with_options: [sprint.name])
      expect(response.body).to have_select("Backlog bucket", with_options: [bucket.name])
    end

    it "orders the assignable sprints chronologically, soonest first" do
      sprint_later = create(:sprint, project:, name: "Sprint later",
                                     start_date: Time.zone.today + 30.days, finish_date: Time.zone.today + 44.days)
      sprint_soon = create(:sprint, project:, name: "Sprint soon",
                                    start_date: Time.zone.today + 7.days, finish_date: Time.zone.today + 20.days)
      sprint_latest = create(:sprint, project:, name: "Sprint latest",
                                      start_date: Time.zone.today + 60.days, finish_date: Time.zone.today + 74.days)

      get edit_work_packages_bulk_path(ids: [work_package1.id, work_package2.id])

      rendered_order = page.all("select[name='work_package[sprint_id]'] option")
                           .map { |option| option.text.strip }
                           # Skip blank and "None" options, we are only interested in the sprints to assert the ordering
                           .intersection([sprint_soon.name, sprint_later.name, sprint_latest.name])

      expect(rendered_order).to eq [sprint_soon.name, sprint_later.name, sprint_latest.name]
    end

    context "without the manage_sprint_items permission" do
      let(:permissions) { %i[view_work_packages edit_work_packages view_sprints] }

      it "does not display the fields" do
        expect(response.body).to have_no_select("Sprint")
        expect(response.body).to have_no_select("Backlog bucket")
      end
    end

    context "when the project does not have backlogs enabled" do
      let(:enabled_modules) { %i[work_package_tracking] }

      it "does not display the fields" do
        expect(response.body).to have_no_select("Sprint")
        expect(response.body).to have_no_select("Backlog bucket")
      end
    end

    context "when the selected work packages span multiple projects" do
      shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
      shared_let(:work_package3) { create(:work_package, project: other_project) }

      before do
        create(:member, project: other_project, principal: user,
                        roles: [create(:project_role, permissions:)])

        get edit_work_packages_bulk_path(ids: [work_package1.id, work_package2.id, work_package3.id])
      end

      it "does not display the fields" do
        expect(response.body).to have_no_select("Sprint")
        expect(response.body).to have_no_select("Backlog bucket")
      end
    end
  end

  describe "PUT update" do
    let(:work_package_ids) { [work_package1.id, work_package2.id] }

    it "assigns the sprint to all selected work packages" do
      put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { sprint_id: sprint.id } }

      expect(work_package1.reload.sprint).to eq sprint
      expect(work_package2.reload.sprint).to eq sprint
    end

    it "assigns the backlog bucket to all selected work packages" do
      put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { backlog_bucket_id: bucket.id } }

      expect(work_package1.reload.backlog_bucket).to eq bucket
      expect(work_package2.reload.backlog_bucket).to eq bucket
    end

    it "clears the sprint when 'none' is selected" do
      work_package1.update!(sprint:)

      put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { sprint_id: "none" } }

      expect(work_package1.reload.sprint).to be_nil
    end

    it "clears an existing sprint when a backlog bucket is assigned instead" do
      work_package1.update!(sprint:)

      put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { backlog_bucket_id: bucket.id } }

      expect(work_package1.reload).to have_attributes(sprint: nil, backlog_bucket: bucket)
    end

    it "clears an existing backlog bucket when a sprint is assigned instead" do
      work_package1.update!(backlog_bucket: bucket)

      put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { sprint_id: sprint.id } }

      expect(work_package1.reload).to have_attributes(sprint:, backlog_bucket: nil)
    end

    it "rejects assigning both a sprint and a backlog bucket in the same submission" do
      put work_packages_bulk_path,
          params: { ids: work_package_ids, work_package: { sprint_id: sprint.id, backlog_bucket_id: bucket.id } }

      expect(flash[:error])
        .to include(I18n.t(:"work_packages.bulk.none_could_be_saved", total: work_package_ids.size))
      expect(work_package1.reload).to have_attributes(sprint: nil, backlog_bucket: nil)
      expect(work_package2.reload).to have_attributes(sprint: nil, backlog_bucket: nil)
    end

    context "without the manage_sprint_items permission" do
      let(:permissions) { %i[view_work_packages edit_work_packages view_sprints] }

      it "does not assign the sprint" do
        put work_packages_bulk_path, params: { ids: work_package_ids, work_package: { sprint_id: sprint.id } }

        expect(work_package1.reload.sprint).to be_nil
      end
    end
  end
end
