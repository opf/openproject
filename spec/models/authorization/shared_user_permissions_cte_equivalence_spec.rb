# frozen_string_literal: true

# -- copyright
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
# ++
require "spec_helper"

# Pins the `shared_user_permissions_cte` flag to result-equivalence: the id-sets
# returned by the authorization scopes must be identical with the flag off (legacy
# inline UNION) and on (provider-backed CTE, inlined here since no collector wraps
# the query).
RSpec.describe "shared_user_permissions_cte equivalence", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  project_permissions = %i[view_work_packages edit_project].freeze

  shared_let(:private_project) { create(:project, public: false) }
  shared_let(:public_project) { create(:project, public: true) }
  # A private project the member below is deliberately NOT a member of.
  shared_let(:inaccessible_project) { create(:project, public: false) }

  shared_let(:wp_in_private) { create(:work_package, project: private_project) }
  shared_let(:wp_in_public) { create(:work_package, project: public_project) }
  shared_let(:wp_in_inaccessible) { create(:work_package, project: inaccessible_project) }

  shared_let(:member_role) { create(:project_role, permissions: %i[view_work_packages edit_project]) }
  shared_let(:member_user) do
    create(:user, member_with_roles: { private_project => member_role })
  end

  shared_let(:non_member_user) { create(:user) }
  shared_let(:admin) { create(:admin) }

  before do
    create(:non_member, permissions: %i[view_work_packages])
    create(:anonymous_role, permissions: %i[view_work_packages])
  end

  def project_ids(user, permission)
    Project.allowed_to(user, permission).order(:id).ids
  end

  def visible_work_package_ids(user)
    WorkPackage.visible(user).order(:id).ids
  end

  users = {
    "a member" => :member_user,
    "a logged-in non-member" => :non_member_user,
    "an admin" => :admin,
    "an anonymous user" => -> { User.anonymous }
  }

  users.each do |label, ref|
    context "for #{label}" do
      let(:user) { ref.is_a?(Symbol) ? public_send(ref) : instance_exec(&ref) }

      project_permissions.each do |permission|
        it "returns the same Project.allowed_to(#{permission}) ids under both flag states" do
          with_flags(shared_user_permissions_cte: false)
          legacy = project_ids(user, permission)

          with_flags(shared_user_permissions_cte: true)
          cte = project_ids(user, permission)

          expect(cte).to eq(legacy)
        end
      end

      it "returns the same WorkPackage.visible ids under both flag states" do
        with_flags(shared_user_permissions_cte: false)
        legacy = visible_work_package_ids(user)

        with_flags(shared_user_permissions_cte: true)
        cte = visible_work_package_ids(user)

        expect(cte).to eq(legacy)
      end
    end
  end

  # Notification.visible embeds WorkPackage.visible, so it exercises the emission nested
  # one level deeper than the direct scopes above.
  context "for a layered scope (Notification.visible over WorkPackage.visible)" do
    shared_let(:member_notification) { create(:notification, recipient: member_user, resource: wp_in_private) }
    shared_let(:decoy_notification) { create(:notification, recipient: member_user, resource: wp_in_inaccessible) }

    it "returns the same Notification.visible ids under both flag states" do
      with_flags(shared_user_permissions_cte: false)
      legacy = Notification.visible(member_user).order(:id).ids

      with_flags(shared_user_permissions_cte: true)
      cte = Notification.visible(member_user).order(:id).ids

      expect(cte).to eq(legacy)
      # Visible for the readable WP, never for the inaccessible one.
      expect(legacy).to include(member_notification.id)
      expect(legacy).not_to include(decoy_notification.id)
    end
  end

  context "when a query embeds the same derivation twice and is wrapped in a collector (flag on)" do
    before { with_flags(shared_user_permissions_cte: true) }

    # The collector marks the ProviderStatement nodes of the scope it wraps, so each
    # assertion builds a fresh scope rather than reusing one instance.
    def double_embed_scope
      Project
        .where(id: Project.allowed_to(member_user, :view_work_packages))
        .where(id: Project.allowed_to(member_user, :view_work_packages))
    end

    def collector_for(scope)
      OpenProject::ActiveRecordExtensions::CteCollector.new(relation: scope)
    end

    it "hoists the derivation into a single shared CTE referenced from each embed" do
      sql = collector_for(double_embed_scope).to_sql

      expect(sql.scan(/user_permissions_\h+" AS/).size).to eq(1)
      expect(sql.scan(/from user_permissions_\h+/).size).to be >= 2
    end

    it "returns the same rows and count as the uncollected query" do
      uncollected_ids = double_embed_scope.pluck(:id)
      collector = collector_for(double_embed_scope)

      expect(collector.pluck(:id)).to match_array(uncollected_ids)
      expect(collector.to_a.map(&:id)).to match_array(uncollected_ids)
      expect(collector.count).to eq(uncollected_ids.size)
    end

    it "does not corrupt the wrapped scope when collecting" do
      scope = double_embed_scope
      collector_for(scope).to_a

      expect { scope.to_a }.not_to raise_error
      expect(scope.to_sql).not_to include("user_permissions")
    end
  end

  # Absolute (not just parity) security assertions with the CTE path active: the
  # collapse must never widen the set of accessible records.
  context "when guarding against privilege escalation (flag on)" do
    before { with_flags(shared_user_permissions_cte: true) }

    it "grants only projects where the member's role carries the permission" do
      expect(Project.allowed_to(member_user, :edit_project)).to contain_exactly(private_project)
    end

    it "never exposes a private project the user is not a member of" do
      expect(Project.allowed_to(member_user, :edit_project)).not_to include(inaccessible_project)
      expect(WorkPackage.visible(member_user)).not_to include(wp_in_inaccessible)
    end

    it "grants nothing to a member whose role lacks the permission" do
      powerless = create(:user, member_with_roles: { private_project => create(:project_role, permissions: []) })

      expect(Project.allowed_to(powerless, :edit_project)).to be_empty
    end

    it "does not let a logged-in non-member reach private projects" do
      expect(Project.allowed_to(non_member_user, :edit_project)).to be_empty
      expect(WorkPackage.visible(non_member_user)).not_to include(wp_in_private, wp_in_inaccessible)
    end

    it "does not grant project-wide access from a work-package-only membership" do
      wp_member = create(:user)
      create(:member,
             principal: wp_member,
             project: inaccessible_project,
             entity: wp_in_inaccessible,
             roles: [create(:work_package_role, permissions: %i[view_work_packages])])

      expect(WorkPackage.visible(wp_member)).to include(wp_in_inaccessible)
      expect(Project.allowed_to(wp_member, :edit_project)).not_to include(inaccessible_project)
    end
  end
end
