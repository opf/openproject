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
require_relative "root_seeder_shared_examples"

RSpec.describe RootSeeder,
               "standard edition",
               with_config: { edition: "standard" } do
  include RootSeederTestHelpers

  shared_examples "creates standard demo data" do
    it "creates the system user" do
      expect(SystemUser.where(admin: true).count).to eq 1
    end

    it "creates an admin user" do
      expect(User.not_builtin.where(admin: true).count).to eq 1
    end

    it "creates the demo data" do
      expect(Project.count).to eq 2
      expect(EnabledModule.count).to eq 13
      expect(WorkPackage.count).to eq 36
      expect(Wiki.count).to eq 2
      expect(Query.having_views.count).to eq 8
      expect(View.where(type: "work_packages_table").count).to eq 5
      expect(View.where(type: "team_planner").count).to eq 1
      expect(View.where(type: "gantt").count).to eq 2
      expect(Query.count).to eq 26
      expect(ProjectRole.count).to eq 5
      expect(WorkPackageRole.count).to eq 3
      expect(GlobalRole.count).to eq 1
      expect(Grids::Overview.count).to eq 2
      expect(Version.count).to eq 4
      expect(VersionSetting.count).to eq 4
      expect(Boards::Grid.count).to eq 5
      expect(Boards::Grid.count { |grid| grid.options.has_key?(:filters) }).to eq 1
    end

    it "links work packages to their version" do
      count_by_version = WorkPackage.joins(:version).group("versions.name").count
      # testing with strings would fail for the German language test
      # 'Bug Backlog' => 1,
      # 'Sprint 1' => 8,
      # 'Product Backlog' => 7
      expect(count_by_version.values).to contain_exactly(1, 8, 7)
    end

    it "adds the backlogs, board, costs, meetings, and reporting modules to the default_projects_modules setting" do
      default_modules = Setting.find_by(name: "default_projects_modules").value
      expect(default_modules).to include("backlogs")
      expect(default_modules).to include("board_view")
      expect(default_modules).to include("costs")
      expect(default_modules).to include("meetings")
      expect(default_modules).to include("reporting_module")
    end

    it "creates a structured meeting of 1h duration" do
      expect(StructuredMeeting.count).to eq 1
      expect(StructuredMeeting.last.duration).to eq 1.0
      expect(MeetingAgendaItem.count).to eq 9
      expect(MeetingAgendaItem.sum(:duration_in_minutes)).to eq 60
    end

    it "creates different types of queries" do
      count_by_type = View.group(:type).count
      expect(count_by_type).to eq(
        "work_packages_table" => 5,
        "gantt" => 2,
        "team_planner" => 1
      )
    end

    it "adds additional permissions from modules" do
      # do not test for all permissions but only some of them to ensure each
      # module got processed for a standard edition
      work_package_editor_role = root_seeder.seed_data.find_reference(:default_role_work_package_editor)
      expect(work_package_editor_role.permissions).to include(
        :view_work_packages, # from common basic data
        :view_own_time_entries, # from costs module
        :view_file_links, # from storages module
        :show_github_content # from github_integration module
      )
      member_role = root_seeder.seed_data.find_reference(:default_role_member)
      expect(member_role.permissions).to include(
        :view_work_packages, # from common basic data
        :view_taskboards, # from backlogs module
        :show_board_views, # from board module
        :view_documents, # from documents module
        :view_budgets, # from costs module
        :view_meetings, # from meeting module
        :view_file_links # from storages module
      )
      expect(member_role.permissions).not_to include(
        :view_linked_issues # from bim module
      )
    end

    include_examples "it creates records", model: Color, expected_count: 144
    include_examples "it creates records", model: DocumentCategory, expected_count: 3
    include_examples "it creates records", model: GlobalRole, expected_count: 1
    include_examples "it creates records", model: WorkPackageRole, expected_count: 3
    include_examples "it creates records", model: ProjectRole, expected_count: 5
    include_examples "it creates records", model: ProjectQueryRole, expected_count: 2
    include_examples "it creates records", model: IssuePriority, expected_count: 4
    include_examples "it creates records", model: Status, expected_count: 14
    include_examples "it creates records", model: TimeEntryActivity, expected_count: 6
    include_examples "it creates records", model: Workflow, expected_count: 1758
    include_examples "it creates records", model: Meeting, expected_count: 1
  end

  describe "demo data" do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_edition("standard") do
        root_seeder.seed_data!
      end
    end

    include_examples "creates standard demo data"

    include_examples "no email deliveries"

    context "when run a second time" do
      before_all do
        described_class.new.seed_data!
      end

      it "does not create additional data" do
        expect(Project.count).to eq 2
        expect(WorkPackage.count).to eq 36
        expect(Wiki.count).to eq 2
        expect(Query.having_views.count).to eq 8
        expect(View.where(type: "work_packages_table").count).to eq 5
        expect(View.where(type: "team_planner").count).to eq 1
        expect(View.where(type: "gantt").count).to eq 2
        expect(Query.count).to eq 26
        expect(ProjectRole.count).to eq 5
        expect(WorkPackageRole.count).to eq 3
        expect(GlobalRole.count).to eq 1
        expect(Grids::Overview.count).to eq 2
        expect(Version.count).to eq 4
        expect(VersionSetting.count).to eq 4
        expect(Boards::Grid.count).to eq 5
      end
    end
  end

  describe "demo data with work package role migration having been run" do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      # call the migration which will add data for work package roles. This
      # needs to be done manually as running tests automatically calls the
      # `db:test:purge` rake task.
      require(Rails.root.join("db/migrate/20231128080650_add_work_package_roles"))
      AddWorkPackageRoles.new.up

      with_edition("standard") do
        root_seeder.seed_data!
      end
    end

    include_examples "creates standard demo data"
  end

  describe "demo data mock-translated in another language" do
    shared_let(:root_seeder) { described_class.new }

    before_all do
      with_edition("standard") do
        # simulate a translation by changing the returned string on `I18n#t` calls
        allow(I18n).to receive(:t).and_wrap_original do |m, *args, **kw|
          original_translation = m.call(*args, **kw)
          "tr: #{original_translation}"
        end
        root_seeder.seed_data!
      end
    end

    include_examples "creates standard demo data"

    it "has all Query.name translated" do
      expect(Query.pluck(:name)).to all(start_with("tr: "))
    end
  end

  [
    "OPENPROJECT_SEED_LOCALE",
    "OPENPROJECT_DEFAULT_LANGUAGE"
  ].each do |env_var_name|
    describe "demo data with a non-English language set with #{env_var_name}",
             :settings_reset do
      shared_let(:root_seeder) { described_class.new }

      before_all do
        with_env(env_var_name => "de") do
          with_edition("standard") do
            reset(:default_language) # Settings are a pain to reset
            root_seeder.seed_data!
          ensure
            reset(:default_language)
          end
        end
      end

      it "seeds with the specified language" do
        willkommen = I18n.t("#{Source::Translate::I18N_PREFIX}.standard.welcome.title", locale: "de")
        expect(Setting.welcome_title).to eq(willkommen)
        expect(Status.where(name: "Neu")).to exist
        expect(Type.where(name: "Meilenstein")).to exist
        expect(Color.where(name: "Gelb")).to exist
      end

      it "sets Setting.default_language to the given language" do
        expect(Setting.find_by(name: "default_language")).to have_attributes(value: "de")
      end

      include_examples "creates standard demo data"
    end
  end

  describe "demo data with development data" do
    shared_let(:root_seeder) { described_class.new(seed_development_data: true) }

    before_all do
      RSpec::Mocks.with_temporary_scope do
        # opportunistic way to add a test for bug #53611 without extending the testing time
        allow(Settings::Definition["default_projects_modules"])
          .to receive(:writable?).and_return(false)

        root_seeder.seed_data!
      end
    end

    it "creates 1 additional admin user with German locale" do
      admins = User.not_builtin.where(admin: true)
      expect(admins.count).to eq 2
      expect(admins.pluck(:language)).to match_array(%w[en de])
    end

    it "creates 5 additional projects for development" do
      expect(Project.count).to eq 7
    end

    it "creates 4 additional work packages for development" do
      expect(WorkPackage.count).to eq 40
    end

    it "creates 1 project with custom fields" do
      expect(CustomField.count).to eq 12
    end

    include_examples "no email deliveries"
  end
end
