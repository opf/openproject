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
require Rails.root.join("db/migrate/20240805104004_rename_visible_to_admin_only_in_custom_fields.rb")

RSpec.describe RenameVisibleToAdminOnlyInCustomFields, type: :model do
  after do
    # Reset after each spec to ensure we have the column information up to date.
    ProjectCustomField.reset_column_information
  end

  context "when migrating up" do
    # Roll back the migration so we can migrate up
    before do
      ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:down) }
    end

    # Silencing migration logs, since we are not interested in that during testing
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

    it "changes the visible field to admin_only and flips the value" do
      ProjectCustomField.new(visible: false).save(validate: false)

      expect { subject }
        .to change { CustomField.first.attributes.slice("visible", "admin_only") }
        .from("visible" => false)
        .to("admin_only" => true)

      # it changes the default value to false
      ProjectCustomField.reset_column_information
      custom_field = ProjectCustomField.new
      custom_field.save(validate: false)

      expect(custom_field.admin_only).to be false
    end
  end

  context "when migrating down" do
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:down) } }

    it "rolls back the admin_only field to visible and flips the value" do
      ProjectCustomField.new(admin_only: false).save(validate: false)

      expect { subject }
        .to change { CustomField.first.attributes.slice("visible", "admin_only") }
        .from("admin_only" => false)
        .to("visible" => true)

      # it changes the default value to tru
      ProjectCustomField.reset_column_information
      custom_field = ProjectCustomField.new
      custom_field.save(validate: false)

      expect(custom_field.visible).to be true
    end
  end
end
