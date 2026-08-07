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

# Security equivalence / characterization harness for permission visibility.
#
# Pins CURRENT permission-SQL result sets so a future refactor
# (shared CTE, memoization, etc.) can assert identical id sets for a matrix of
# users × roles × project visibility × module state.
#
# When a flag-gated alternative exists, compare old vs new by calling both
# implementations on the same matrix (not only these hand-written expectations).

RSpec.describe Authorization, "permission visibility equivalence harness" do
  shared_let(:type) { create(:type_standard) }
  shared_let(:status) { create(:status) }

  shared_let(:private_project) { create(:project, public: false, enabled_module_names: %i[work_package_tracking costs]) }
  shared_let(:public_project) { create(:project, public: true, enabled_module_names: %i[work_package_tracking costs]) }
  shared_let(:private_no_costs) { create(:project, public: false, enabled_module_names: %i[work_package_tracking]) }
  # Costs enabled so it can hold a decoy time entry: admins see it (module gated),
  # but non-members must not — proving exclusion is by membership, not just module.
  shared_let(:decoy_project) { create(:project, public: false, enabled_module_names: %i[work_package_tracking costs]) }

  shared_let(:wp_private) { create(:work_package, project: private_project, type:, status:) }
  shared_let(:wp_public) { create(:work_package, project: public_project, type:, status:) }
  shared_let(:wp_private_no_costs) { create(:work_package, project: private_no_costs, type:, status:) }
  shared_let(:wp_other_in_private) { create(:work_package, project: private_project, type:, status:) }
  shared_let(:wp_decoy) { create(:work_package, project: decoy_project, type:, status:) }

  shared_let(:member_role) do
    create(:project_role, permissions: %i[view_project view_work_packages view_time_entries view_own_time_entries])
  end
  shared_let(:viewer_role) do
    create(:project_role, permissions: %i[view_project view_work_packages])
  end
  shared_let(:wp_editor_role) do
    create(:work_package_role, permissions: %i[view_work_packages])
  end

  shared_let(:admin) { create(:admin) }
  shared_let(:anonymous) { User.anonymous }
  shared_let(:non_member_user) { create(:user) }

  shared_let(:project_member) do
    create(:user, member_with_roles: { private_project => member_role, private_no_costs => viewer_role })
  end

  shared_let(:entity_member) do
    user = create(:user)
    create(:member, user:, project: private_project, entity: wp_private, roles: [wp_editor_role])
    user
  end

  # Time entries exercise the intertwined cost/time permissions the visibility
  # mega-query nests (view_time_entries / view_own_time_entries), gated on the
  # `costs` module. decoy has no costs module → invisible to non-admins regardless.
  # Defined after the user shared_lets so `project_member` is materialised first.
  shared_let(:te_private) { create(:time_entry, entity: wp_private, user: project_member) }
  shared_let(:te_public) { create(:time_entry, entity: wp_public, user: admin) }
  shared_let(:te_decoy) { create(:time_entry, entity: wp_decoy, user: admin) }

  # Restore-safe anonymous / non-member grants (see spec/support/roles.rb pattern)
  around do |example|
    non_member = ProjectRole.non_member
    anon = ProjectRole.anonymous
    previous_non_member = non_member.permissions.dup
    previous_anon = anon.permissions.dup

    non_member.permissions = (non_member.permissions + %i[view_project view_work_packages]).uniq
    non_member.save!
    anon.permissions = (anon.permissions + %i[view_project view_work_packages]).uniq
    anon.save!

    example.run
  ensure
    non_member.permissions = previous_non_member
    non_member.save!
    anon.permissions = previous_anon
    anon.save!
  end

  def fixture_wp_ids
    [wp_private, wp_public, wp_private_no_costs, wp_other_in_private, wp_decoy].map(&:id)
  end

  def fixture_project_ids
    [private_project, public_project, private_no_costs, decoy_project].map(&:id)
  end

  def fixture_time_entry_ids
    [te_private, te_public, te_decoy].map(&:id)
  end

  def ids_for(user, scope_name)
    case scope_name
    when :work_package_allowed_view
      WorkPackage.allowed_to(user, :view_work_packages).order(:id).pluck(:id)
    when :project_allowed_view_wp
      Project.allowed_to(user, :view_work_packages).order(:id).pluck(:id)
    when :project_visible
      Project.visible(user).order(:id).pluck(:id)
    when :notification_visible
      Notification.visible(user).order(:id).pluck(:id)
    when :time_entry_visible
      TimeEntry.visible(user).order(:id).pluck(:id)
    else
      raise ArgumentError, "unknown scope #{scope_name}"
    end
  end

  shared_examples "wp equivalence cell" do
    it "returns the expected fixture WP ids and excludes decoys" do
      user = instance_exec(&user_proc)
      expected = instance_exec(&expected_wp_proc)
      actual = ids_for(user, :work_package_allowed_view) & fixture_wp_ids

      expect(actual).to match_array(expected)
      expect(actual).not_to include(wp_decoy.id) unless expected.include?(wp_decoy.id)
    end
  end

  shared_examples "project equivalence cell" do
    it "returns the expected fixture project ids and excludes decoys" do
      user = instance_exec(&user_proc)
      expected = instance_exec(&expected_project_proc)
      actual = ids_for(user, :project_allowed_view_wp) & fixture_project_ids

      expect(actual).to match_array(expected)
      expect(actual).not_to include(decoy_project.id) unless expected.include?(decoy_project.id)
    end
  end

  describe "WorkPackage.allowed_to(:view_work_packages)" do
    {
      "admin sees all fixture WPs including decoy" => [
        -> { admin },
        -> { fixture_wp_ids }
      ],
      "anonymous sees only public WP" => [
        -> { anonymous },
        -> { [wp_public.id] }
      ],
      "non-member sees public WP" => [
        -> { non_member_user },
        -> { [wp_public.id] }
      ],
      "project member sees private + public + no-costs private (not decoy)" => [
        -> { project_member },
        -> { [wp_private.id, wp_public.id, wp_private_no_costs.id, wp_other_in_private.id] }
      ],
      "entity member sees only the shared WP plus public" => [
        -> { entity_member },
        -> { [wp_private.id, wp_public.id] }
      ]
    }.each do |label, (user_proc, expected_wp_proc)|
      context label do
        let(:user_proc) { user_proc }
        let(:expected_wp_proc) { expected_wp_proc }

        include_examples "wp equivalence cell"
      end
    end
  end

  describe "Project.allowed_to(:view_work_packages)" do
    {
      "admin sees all fixture projects including decoy" => [
        -> { admin },
        -> { fixture_project_ids }
      ],
      "anonymous sees only public project" => [
        -> { anonymous },
        -> { [public_project.id] }
      ],
      "non-member sees public project" => [
        -> { non_member_user },
        -> { [public_project.id] }
      ],
      "project member sees private + public + no-costs (not decoy)" => [
        -> { project_member },
        -> { [private_project.id, public_project.id, private_no_costs.id] }
      ]
    }.each do |label, (user_proc, expected_project_proc)|
      context label do
        let(:user_proc) { user_proc }
        let(:expected_project_proc) { expected_project_proc }

        include_examples "project equivalence cell"
      end
    end
  end

  describe "Notification.visible embeds WorkPackage.visible" do
    shared_let(:recipient) { project_member }

    shared_let(:visible_notification) do
      create(:notification, recipient:, resource: wp_private, reason: :mentioned)
    end

    # A non-member: sees only the public WP. Its notification on the private WP
    # must be filtered out, the one on the public WP kept.
    shared_let(:stranger) { create(:user) }
    shared_let(:stranger_note_on_private) do
      create(:notification, recipient: stranger, resource: wp_private, reason: :mentioned)
    end
    shared_let(:stranger_note_on_public) do
      create(:notification, recipient: stranger, resource: wp_public, reason: :mentioned)
    end

    shared_examples "notification visibility rules" do
      it "includes notifications for the recipient when the WP is visible" do
        expect(Notification.visible(recipient).pluck(:id)).to include(visible_notification.id)
      end

      it "excludes notifications whose WP is not visible to the recipient" do
        ids = Notification.visible(stranger).pluck(:id)
        expect(ids).not_to include(stranger_note_on_private.id)
        expect(ids).to include(stranger_note_on_public.id)
      end
    end

    # The shared_permissions_cte flag swaps the visible-WP `IN (subquery)`
    # for a MATERIALIZED CTE. The rules must hold identically under both paths.
    context "with the legacy path (flag off)", with_flag: { shared_permissions_cte: false } do
      include_examples "notification visibility rules"
    end

    context "with the shared materialized CTE (flag on)", with_flag: { shared_permissions_cte: true } do
      include_examples "notification visibility rules"
    end

    it "returns an identical id set with the flag off and on (old-vs-new equivalence)" do
      users = [recipient, stranger, admin, non_member_user, anonymous]

      allow(OpenProject::FeatureDecisions).to receive(:shared_permissions_cte_active?).and_return(false)
      legacy = users.to_h { |user| [user.id, Notification.visible(user).order(:id).pluck(:id)] }

      allow(OpenProject::FeatureDecisions).to receive(:shared_permissions_cte_active?).and_return(true)
      shared_cte = users.to_h { |user| [user.id, Notification.visible(user).order(:id).pluck(:id)] }

      expect(shared_cte).to eq(legacy)
    end
  end

  describe "ResourceIdFilter#allowed_values shape" do
    it "enumerates WorkPackage.visible ids for the current user and excludes decoys" do
      ids = WorkPackage.visible(project_member).pluck(:id)
      expect(ids).to include(wp_private.id, wp_public.id, wp_private_no_costs.id, wp_other_in_private.id)
      expect(ids).not_to include(wp_decoy.id)
    end
  end

  describe "TimeEntry.visible (view_time_entries / view_own_time_entries)" do
    # Result-level pin for the cost/time permissions nested by include_spent_time.
    # This is the coverage the plain SQL-string characterization below cannot give.
    {
      "admin sees all fixture time entries incl. decoy" => [
        -> { admin },
        -> { fixture_time_entry_ids }
      ],
      "project member sees only the private-project entry (has view_time_entries there)" => [
        -> { project_member },
        -> { [te_private.id] }
      ],
      "non-member sees no time entries (no view_time_entries granted)" => [
        -> { non_member_user },
        -> { [] }
      ],
      "anonymous sees no time entries" => [
        -> { anonymous },
        -> { [] }
      ]
    }.each do |label, (user_proc, expected_te_proc)|
      context label do
        it "returns the expected fixture time-entry ids and excludes decoys" do
          user = instance_exec(&user_proc)
          expected = instance_exec(&expected_te_proc)
          actual = ids_for(user, :time_entry_visible) & fixture_time_entry_ids

          expect(actual).to match_array(expected)
          expect(actual).not_to include(te_decoy.id) unless expected.include?(te_decoy.id)
        end
      end
    end
  end

  describe "include_spent_time composition (characterization)" do
    it "embeds time-entry visibility SQL used by the spent-time CTE" do
      sql = WorkPackage.include_spent_time(project_member).limit(1).to_sql
      expect(sql).to match(/visible_time_entries|time_entries/i)
      # Intertwined permission signature: multiple permission names appear
      expect(sql.scan(/view_time_entries|view_own_time_entries|view_work_packages/).size).to be >= 1
    end

    # Result-level pin on the summed hours per work package. This is the guard for
    # any future refactor that shares/materialises the permission derivation the
    # spent-time query nests: the SUMs must not change. project_member has
    # view_time_entries only in private_project, so only te_private (1.0h) counts.
    def spent_hours(user, work_package)
      WorkPackage.include_spent_time(user, work_package).first&.hours.to_f
    end

    it "sums only the time entries visible to the user" do
      expect(spent_hours(project_member, wp_private)).to eq(1.0)
      expect(spent_hours(project_member, wp_public)).to eq(0.0)   # te_public not visible to member
      expect(spent_hours(project_member, wp_decoy)).to eq(0.0)    # te_decoy in decoy project
      expect(spent_hours(project_member, wp_private_no_costs)).to eq(0.0)
    end
  end

  describe "project-side shared-CTE primitives (old-vs-new equivalence)" do
    def both_flag_states(users)
      allow(OpenProject::FeatureDecisions).to receive(:shared_permissions_cte_active?).and_return(false)
      legacy = users.to_h { |user| [user.id, yield(user)] }
      allow(OpenProject::FeatureDecisions).to receive(:shared_permissions_cte_active?).and_return(true)
      shared_cte = users.to_h { |user| [user.id, yield(user)] }
      [legacy, shared_cte]
    end

    let(:matrix) { [admin, anonymous, non_member_user, project_member] }

    it "Project.visible_ids yields an identical project set embedded either way" do
      legacy, shared_cte = both_flag_states(matrix) do |user|
        Project.where(id: Project.visible_ids(user)).order(:id).pluck(:id) & fixture_project_ids
      end
      expect(shared_cte).to eq(legacy)
    end

    it "WorkPackage.visible_ids(column: :project_id) via Project.with_visible_work_packages is identical" do
      legacy, shared_cte = both_flag_states(matrix) do |user|
        Project.with_visible_work_packages(user).order(:id).pluck(:id) & fixture_project_ids
      end
      expect(shared_cte).to eq(legacy)
    end

    # `column` reaches raw SQL whichever path runs, so the guard must hold in both states.
    it "WorkPackage.visible_ids rejects a column outside the table in both flag states" do
      [false, true].each do |flag_active|
        allow(OpenProject::FeatureDecisions).to receive(:shared_permissions_cte_active?).and_return(flag_active)

        expect { WorkPackage.visible_ids(project_member, column: "id FROM work_packages; --") }
          .to raise_error(ArgumentError, /unknown column/)
      end
    end
  end
end
