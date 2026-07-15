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
require_relative "../../../../spec/seeders/root_seeder_shared_examples"

RSpec.describe RootSeeder,
               "BIM edition",
               with_config: { edition: "bim" } do
  include RootSeederTestHelpers

  before_all do
    week_with_saturday_and_sunday_as_weekend
    clear_enqueued_jobs
    clear_performed_jobs
  end

  shared_examples "creates BIM demo data" do
    def group_name(reference)
      root_seeder.seed_data.find_reference(reference)["name"]
    end

    it "creates an admin user" do
      expect(User.not_builtin.where(admin: true).count).to eq 1
    end

    it "creates the BIM demo data" do
      expect(Project.count).to eq 4
      expect(EnabledModule.count).to eq 29
      expect(WorkPackage.count).to eq 76
      expect(Wiki.count).to eq 3
      expect(Query.count).to eq 29
      expect(Group.count).to eq 8
      expect(Type.count).to eq 7
      expect(Status.count).to eq 4
      expect(IssuePriority.count).to eq 4
      expect(Bim::IfcModels::IfcModel.count).to eq 3
      expect(Grids::Overview.count).to eq 4
      expect(Boards::Grid.count).to eq 2
    end

    it "adds the BIM module to the default_projects_modules setting" do
      default_modules = Setting.find_by(name: "default_projects_modules").value
      expect(default_modules).to include("bim")
    end

    it "creates follows and parent-child relations" do
      expect(Relation.follows.count).to eq 35
      expect(WorkPackage.where.not(parent: nil).count).to eq 55
    end

    it "assigns work packages to groups" do
      count_by_assignee =
        WorkPackage
          .joins(:assigned_to)
          .group("array_to_string(array_remove(ARRAY[type || ':', firstname, lastname], ''), ' ')")
          .count
      # .transform_keys! { |key| key.squish.gsub('tr: ', '') }
      expect(count_by_assignee).to eq(
        "Group: #{group_name(:group__architects)}" => 1,
        "Group: #{group_name(:group__bim_coordinators)}" => 11,
        "Group: #{group_name(:group__bim_managers)}" => 2,
        "Group: #{group_name(:group__bim_modellers)}" => 21,
        "Group: #{group_name(:group__lead_bim_coordinators)}" => 8,
        "Group: #{group_name(:group__planners)}" => 21,
        "User: #{root_seeder.admin_user.name}" => 12
      )
    end

    it "adds additional permissions from modules" do
      # do not test for all permissions but only some of them to ensure the ones
      # for BIM got processed
      member_role = root_seeder.seed_data.find_reference(:default_role_member)
      expect(member_role.permissions).to include(
        :view_work_packages, # from common basic data
        :view_linked_issues # from bim module
      )
    end

    include_examples "it creates records", model: Color, expected_count: 148
    include_examples "it creates records", model: DocumentType, expected_count: 6
    include_examples "it creates records", model: IssuePriority, expected_count: 4
    include_examples "it creates records", model: Status, expected_count: 4
    include_examples "it creates records", model: TimeEntryActivity, expected_count: 3
    include_examples "it creates records", model: Workflow, expected_count: 273
    include_examples "it is compatible with the automatic scheduling mode"
  end

  describe "demo data" do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_edition("bim") do
        root_seeder.seed!
      end
    end

    include_examples "creates BIM demo data"

    include_examples "no email deliveries"

    context "when run a second time in a different language", :settings_reset do
      before_all do
        with_locale_env("de") do
          with_edition("bim") do
            described_class.new.seed!
          end
        end
      end

      it "does not create additional data and does not raise any errors" do
        expect(Project.count).to eq 4
        expect(WorkPackage.count).to eq 76
        expect(Wiki.count).to eq 3
        expect(Query.count).to eq 29
        expect(Group.count).to eq 8
        expect(Type.count).to eq 7
        expect(Status.count).to eq 4
        expect(IssuePriority.count).to eq 4
        expect(Bim::IfcModels::IfcModel.count).to eq 3
        expect(Grids::Overview.count).to eq 4
        expect(Boards::Grid.count).to eq 2
      end
    end

    context "when run a second time after all demo projects and original statuses " \
            "and workflows are deleted (Bug #65138)", :settings_reset do
      before_all do
        # Simulate a user having created new statuses, and deleted all default
        # statuses and workflows (making looking up statuses by name impossible)
        new_status = create(:status, :default, name: "My own default status")
        Project.destroy_all
        # destroying all statuses will destroy all workflows by cascade
        Status.where.not(id: new_status.id).destroy_all
        described_class.new.seed!
      end

      it "does not create additional data and does not raise any errors" do
        # seeding does not recreate demo projects
        expect(Project.count).to eq 0
        expect(WorkPackage.count).to eq 0
      end
    end
  end

  describe "demo data mock-translated in another language" do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_edition("bim") do
        # simulate a translation by changing the returned string on `I18n#t` calls
        allow(I18n).to receive(:t).and_wrap_original do |m, *args, **kw|
          original_translation = m.call(*args, **kw)
          "tr: #{original_translation}"
        end

        root_seeder.seed!
      end
    end

    include_examples "creates BIM demo data"

    it "has all Query.name translated" do
      expect(Query.pluck(:name)).to all(start_with("tr: "))
    end

    context "for work packages NOT related to a BCF issue" do
      let(:work_packages) { WorkPackage.left_joins(:bcf_issue).where("bcf_issues.id": nil) }

      %w[subject description].each do |field|
        it "have their #{field} field translated" do
          expect(work_packages.pluck(:subject)).to all(start_with("tr: "))
        end
      end
    end

    # TODO: the data coming from BCF files should be translated too
    # This is recorded in the implementation work package 47998
    context "for work packages related to a BCF issue" do
      let(:work_packages) { WorkPackage.joins(:bcf_issue).where.not("bcf_issues.id": nil) }

      %w[subject description].each do |field|
        it "have NOT their #{field} field translated" do
          expect(work_packages.pluck(:subject)).to all(not_start_with("tr: "))
        end
      end
    end
  end

  describe "demo data with a non-English language set with OPENPROJECT_DEFAULT__LANGUAGE",
           :settings_reset do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_locale_env("de", env_var_name: "OPENPROJECT_DEFAULT__LANGUAGE") do
        with_edition("bim") do
          root_seeder.seed!
        end
      end
    end

    it "seeds with the specified language" do
      expect(Status.where(name: "Neu")).to exist
      expect(Type.where(name: "Meilenstein")).to exist
      expect(Color.where(name: "Gelb")).to exist
    end

    include_examples "creates BIM demo data"
  end

  describe "demo data with development data" do
    shared_let(:root_seeder) { described_class.new(seed_development_data: true) }

    before_all do
      with_edition("bim") do
        RSpec::Mocks.with_temporary_scope do
          # opportunistic way to add a test for bug #53611 without extending the testing time
          allow(Settings::Definition["default_projects_modules"])
              .to receive(:writable?).and_return(false)

          root_seeder.seed!
        end
      end
    end

    it "creates 1 additional admin user with German locale" do
      admins = User.not_builtin.where(admin: true)
      expect(admins.count).to eq 2
      expect(admins.pluck(:language)).to match_array(%w[en de])
    end

    it "creates 5 additional projects for development" do
      expect(Project.count).to eq 9
    end

    it "creates 4 additional work packages for development" do
      expect(WorkPackage.count).to eq 80
    end

    it "creates 1 project with custom fields" do
      # 12 development work package custom fields + 4 demo user custom fields
      expect(CustomField.count).to eq 16
    end

    it "creates 2 additional types for development" do
      expect(Type.count).to eq 9
    end

    include_examples "no email deliveries"
  end

  context "when admin user creation is locked with OPENPROJECT_SEED_ADMIN_USER_LOCKED=true",
          :settings_reset do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_env("OPENPROJECT_SEED_ADMIN_USER_LOCKED" => "true") do
        with_edition("bim") do
          reset(:seed_admin_user_locked)
          root_seeder.seed!
        end
      end
    ensure
      reset(:seed_admin_user_locked)
      RequestStore.clear! # resets `User.current` cached result
    end

    it "seeds without any errors, but locks the admin user", :aggregate_failures do
      expect(Project.count).to eq 4
      expect(WorkPackage.count).to eq 76
      expect(root_seeder.admin_user).to be_locked
    end
  end
end
