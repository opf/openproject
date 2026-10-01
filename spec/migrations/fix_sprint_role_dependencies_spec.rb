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

require Rails.root.join("db/migrate/20260304160505_fix_sprint_role_dependencies")

RSpec.describe FixSprintRoleDependencies, type: :model do
  let!(:role) { create(:project_role, permissions:, add_public_permissions: false) }

  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  describe "completing depencencies for view_sprints permission" do
    context "when view_work_packages is missing" do
      let(:permissions) { [:view_sprints] }

      it "adds view_work_packages" do
        expect { migrate }
          .to change { role.reload.permissions }
          .from(match_array(%i[view_sprints]))
          .to(match_array(%i[view_sprints view_work_packages]))
      end
    end

    context "when view_work_packages is present" do
      let(:permissions) { %i[view_sprints view_work_packages] }

      it "does not duplicate view_work_packages" do
        expect { migrate }.not_to change { role.reload.permissions }
      end
    end
  end

  describe "completing dependencies for create_sprints permission" do
    context "when view_sprints and view_work_packages are missing" do
      let(:permissions) { [:create_sprints] }

      it "adds view_sprints and view_work_packages" do
        expect { migrate }
          .to change { role.reload.permissions }
          .from(match_array(%i[create_sprints]))
          .to(match_array(%i[create_sprints view_sprints view_work_packages]))
      end
    end

    context "when view_work_packages is present" do
      let(:permissions) { %i[create_sprints view_work_packages] }

      it "adds view_sprints" do
        expect { migrate }
          .to change { role.reload.permissions }
          .from(match_array(%i[create_sprints view_work_packages]))
          .to(match_array(%i[create_sprints view_sprints view_work_packages]))
      end
    end

    context "when view_sprints and view_work_packages are present" do
      let(:permissions) { %i[create_sprints view_sprints view_work_packages] }

      it "does not change the permissions" do
        expect { migrate }.not_to change { role.reload.permissions }
      end
    end
  end

  describe "completing dependencies for manage_sprint_items permission" do
    context "when view_sprints and view_work_packages are missing" do
      let(:permissions) { [:manage_sprint_items] }

      it "adds view_sprints and view_work_packages" do
        expect { migrate }
          .to change { role.reload.permissions }
          .from(match_array(%i[manage_sprint_items]))
          .to(match_array(%i[manage_sprint_items view_sprints view_work_packages]))
      end
    end

    context "when view_work_packages is present" do
      let(:permissions) { %i[manage_sprint_items view_work_packages] }

      it "adds view_sprints" do
        expect { migrate }
          .to change { role.reload.permissions }
          .from(match_array(%i[manage_sprint_items view_work_packages]))
          .to(match_array(%i[manage_sprint_items view_sprints view_work_packages]))
      end
    end

    context "when view_sprints and view_work_packages are present" do
      let(:permissions) { %i[manage_sprint_items view_sprints view_work_packages] }

      it "does not change the permissions" do
        expect { migrate }.not_to change { role.reload.permissions }
      end
    end
  end

  describe "completing combined dependencies with view_work_packages missing" do
    let(:permissions) { %i[view_sprints create_sprints manage_sprint_items] }

    it "adds view_work_packages without duplicating view_sprints" do
      expect { migrate }
        .to change { role.reload.permissions }
        .from(match_array(%i[view_sprints create_sprints manage_sprint_items]))
        .to(match_array(%i[view_sprints create_sprints manage_sprint_items view_work_packages]))
    end
  end

  describe "not copmpleting dependencies for other roles" do
    let(:permissions) { [:edit_work_packages] }

    it "does not change the permissions" do
      expect { migrate }.not_to change { role.reload.permissions }
    end
  end
end
