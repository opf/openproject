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
require Rails.root.join("db/migrate/20240206173841_fix_untranslated_work_package_roles.rb")

RSpec.describe FixUntranslatedWorkPackageRoles, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  context "when work package roles are already present" do
    before do
      create(:work_package_role, builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR, name: "foo")
      create(:work_package_role, builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_COMMENTER, name: "bar")
      create(:work_package_role, builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_VIEWER, name: "baz")
    end

    it "updates them with correct names" do
      expect { run_migration }
        .not_to change(WorkPackageRole, :count).from(3)

      expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR))
        .to have_attributes(name: "Work package editor")
      expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_COMMENTER))
        .to have_attributes(name: "Work package commenter")
      expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_VIEWER))
        .to have_attributes(name: "Work package viewer")
    end

    [
      "OPENPROJECT_SEED_LOCALE",
      "OPENPROJECT_DEFAULT_LANGUAGE"
    ].each do |env_var_name|
      describe "when #{env_var_name} is set with a non-English language", :settings_reset do
        it "renames the work package roles in the language specified", :settings_reset do
          with_env(env_var_name => "de") do
            reset(:default_language)
            run_migration
          ensure
            reset(:default_language)
          end

          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR))
            .to have_attributes(name: "Arbeitspaket-Bearbeiter")
          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_COMMENTER))
            .to have_attributes(name: "Arbeitspaket-Kommentator")
          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_VIEWER))
            .to have_attributes(name: "Arbeitspaket-Betrachter")
        end
      end

      describe "when #{env_var_name} is set with an unsupported language", :settings_reset do
        it "uses the English name", :settings_reset do
          allow(Setting).to receive(:default_language).and_return("pt-br")
          run_migration

          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR))
            .to have_attributes(name: "Work package editor")
          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_COMMENTER))
            .to have_attributes(name: "Work package commenter")
          expect(WorkPackageRole.find_by(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_VIEWER))
            .to have_attributes(name: "Work package viewer")
        end
      end
    end
  end
end
