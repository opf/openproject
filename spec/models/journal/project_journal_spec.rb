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

RSpec.describe Journal::ProjectJournal do
  describe "#render_detail" do
    let(:project) { build(:project) }
    let(:journal) { build(:project_journal, journable: project) }

    # The parent of a project is only named to readers who may see it.
    current_user { build_stubbed(:admin) }

    it "renders identifier field correctly" do
      html = journal.render_detail(["identifier", [nil, "my-project"]], html: true)
      expect(html).to eq("<strong>Identifier</strong> set to " \
                         "<i>my-project</i>")

      html = journal.render_detail(["identifier", [nil, "my-project"]], html: false)
      expect(html).to eq("Identifier set to my-project")

      html = journal.render_detail(["identifier", ["my-project", "my-beautiful-project"]], html: true)
      expect(html).to eq("<strong>Identifier</strong> changed from <i>my-project</i> " \
                         "to <i>my-beautiful-project</i>")

      html = journal.render_detail(["identifier", ["my-project", "my-beautiful-project"]], html: false)
      expect(html).to eq("Identifier changed from my-project to my-beautiful-project")
    end

    it "renders name field correctly" do
      html = journal.render_detail(["name", [nil, "Test Project 123"]], html: true)
      expect(html).to eq("<strong>Name</strong> set to " \
                         "<i>Test Project 123</i>")

      html = journal.render_detail(["name", [nil, "Test Project 123"]], html: false)
      expect(html).to eq("Name set to Test Project 123")

      html = journal.render_detail(["name", ["Old Project Name", "New Project Name"]], html: true)
      expect(html).to eq("<strong>Name</strong> changed from <i>Old Project Name</i> " \
                         "to <i>New Project Name</i>")

      html = journal.render_detail(["name", ["Old Project Name", "New Project Name"]], html: false)
      expect(html).to eq("Name changed from Old Project Name to New Project Name")
    end

    it "renders parent field correctly" do
      parent = create(:project)

      # Set
      expect(journal.render_detail(["parent_id", [nil, parent.id]], html: true))
        .to eq("<strong>Subproject of</strong> <i>#{parent.name}</i>")
      expect(journal.render_detail(["parent_id", [nil, parent.id]], html: false))
        .to eq("Subproject of #{parent.name}")

      previous_parent = create(:project)

      # Change
      expect(journal.render_detail(["parent_id", [previous_parent.id, parent.id]], html: true))
        .to eq("<strong>Subproject</strong> changed " \
               "from <i>#{previous_parent.name}</i> to <i>#{parent.name}</i>")
      expect(journal.render_detail(["parent_id", [previous_parent.id, parent.id]], html: false))
        .to eq("Subproject changed from #{previous_parent.name} to #{parent.name}")

      # Delete
      expect(journal.render_detail(["parent_id", [parent.id, nil]], html: true))
        .to eq("<strong>No longer subproject of</strong> <i>#{parent.name}</i>")
      expect(journal.render_detail(["parent_id", [parent.id, nil]], html: false))
        .to eq("No longer subproject of #{parent.name}")
    end

    context "for custom field view_permission" do
      shared_let(:project) { create(:project) }
      shared_let(:custom_field) { create(:string_project_custom_field) }
      shared_let(:key) { "custom_fields_#{custom_field.id}" }

      subject { journal.render_detail([key, [nil, "value"]]) }

      before { login_as(user) }

      context "for a member" do
        let(:user) do
          create(:user, member_with_permissions: { project => %i[view_project_attributes] })
        end

        it "renders details" do
          expect(subject).to include(custom_field.name)
          expect(subject).not_to include(I18n.t(:text_journal_permission_denied))
        end

        context "with a non-existing custom field (or deleted)" do
          shared_let(:key) { "custom_fields_#{custom_field.id + 1}" }

          it "renders permission denied" do
            expect(subject).not_to include(custom_field.name)
            expect(subject).to include(I18n.t(:text_journal_permission_denied))
          end
        end
      end

      context "for an admin" do
        let(:user) { create(:admin) }

        it "renders details" do
          expect(subject).to include(custom_field.name)
          expect(subject).not_to include(I18n.t(:text_journal_permission_denied))
        end
      end
    end
  end
end
