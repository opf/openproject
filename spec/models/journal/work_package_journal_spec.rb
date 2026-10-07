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

RSpec.describe Journal::WorkPackageJournal do
  describe "#render_detail" do
    shared_let(:type) { create(:type) }
    shared_let(:project) { create(:project, types: [type]) }
    shared_let(:other_project) { create(:project) }

    # Visible: assigned to the work package's own project and type.
    shared_let(:visible_custom_field) do
      create(:boolean_wp_custom_field, projects: [project], types: [type])
    end
    # Hidden: assigned to the type, but only mapped to a different project.
    shared_let(:hidden_custom_field) do
      create(:boolean_wp_custom_field, projects: [other_project], types: [type])
    end

    shared_let(:work_package) { create(:work_package, project:, type:) }

    let(:journal) { work_package.last_journal }

    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "renders a custom field assigned to the work package's project/type normally" do
      rendered = journal.render_detail(["custom_fields_#{visible_custom_field.id}", [nil, "t"]])

      expect(rendered).to include(visible_custom_field.name)
      expect(rendered).not_to include(I18n.t(:text_journal_permission_denied))
    end

    it "hides a custom field not assigned to the work package's project/type" do
      rendered = journal.render_detail(["custom_fields_#{hidden_custom_field.id}", [nil, "t"]])

      expect(rendered).not_to include(hidden_custom_field.name)
      expect(rendered).to include(I18n.t(:text_journal_permission_denied))
    end

    it "renders a custom field that has since been deleted as such" do
      deleted = create(:string_wp_custom_field, projects: [project], types: [type])
      key = "custom_fields_#{deleted.id}"
      deleted.destroy!

      rendered = journal.render_detail([key, ["894", nil]])

      expect(rendered).to include(I18n.t(:label_deleted_custom_field))
      expect(rendered).not_to include(I18n.t(:text_journal_permission_denied))
    end

    it "does not render a permission error on a journal created after a custom field was deleted",
       with_settings: { journal_aggregation_time_minutes: 0 } do
      custom_field = create(:list_wp_custom_field, projects: [project], types: [type])
      updated_work_package = create(:work_package, project:, type:, subject: "Before")
      updated_work_package.update!(custom_field_values: { custom_field.id => custom_field.custom_options.first.id })
      custom_field.destroy!

      updated_work_package.reload.update!(subject: "After")

      last_journal = updated_work_package.last_journal
      rendered = last_journal.details.filter_map { |detail| last_journal.render_detail(detail) }

      expect(rendered).to contain_exactly(a_string_including("After"),
                                          a_string_including(I18n.t(:label_deleted_custom_field)))
    end

    describe "the backing visibility check (N+1 guard)" do
      let(:formatter) { OpenProject::JournalFormatter::CustomField::Plain.new(journal) }

      it "does not re-query the visible custom field ids for a project already checked" do
        formatter.send(:visible_custom_field_ids, project) # warms the cache

        expect { formatter.send(:visible_custom_field_ids, project) }.to have_a_query_limit(0)
      end
    end
  end
end
