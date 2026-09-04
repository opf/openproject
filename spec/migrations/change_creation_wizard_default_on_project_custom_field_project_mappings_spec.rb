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
require Rails.root.join("db/migrate/20260805122307_change_creation_wizard_default_on_project_custom_field_project_mappings")

RSpec.describe ChangeCreationWizardDefaultOnProjectCustomFieldProjectMappings, type: :model do
  let(:conn) { ActiveRecord::Base.connection }

  def creation_wizard_default
    ProjectCustomFieldProjectMapping.reset_column_information
    ProjectCustomFieldProjectMapping.column_defaults["creation_wizard"]
  end

  # The test schema is already migrated (default: false). Reset it back to
  # the post-migration state after every example so later specs in the same
  # process don't inherit a stale column cache or a lingering default: true,
  # regardless of which direction this migration's specs just exercised.
  after do
    ActiveRecord::Migration.suppress_messages do
      conn.change_column_default(:project_custom_field_project_mappings, :creation_wizard, false)
    end
    ProjectCustomFieldProjectMapping.reset_column_information
  end

  describe "up migration" do
    before do
      # Put the schema back into the pre-migration state (default: true).
      ActiveRecord::Migration.suppress_messages do
        conn.change_column_default(:project_custom_field_project_mappings, :creation_wizard, true)
      end
    end

    it "changes the column default from true to false" do
      expect(creation_wizard_default).to be true

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(creation_wizard_default).to be false
    end

    it "does not change the creation_wizard value of already existing mappings" do
      mapping = create(:project_custom_field_project_mapping, creation_wizard: true)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(mapping.reload.creation_wizard).to be true
    end

    it "makes newly created mappings default to false" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      mapping = create(:project_custom_field_project_mapping)

      expect(mapping.creation_wizard).to be false
    end
  end

  describe "down migration" do
    it "changes the column default from false back to true" do
      expect(creation_wizard_default).to be false

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(creation_wizard_default).to be true
    end

    it "does not change the creation_wizard value of already existing mappings" do
      mapping = create(:project_custom_field_project_mapping, creation_wizard: false)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(mapping.reload.creation_wizard).to be false
    end
  end
end
