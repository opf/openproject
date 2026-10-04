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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

# Regression guard for COMMS-837: the XLS cost-report export must render the
# work package's display identifier in the "Logged for" column, so semantic
# identifiers (e.g. "PROJ-42") appear instead of the numeric id.
RSpec.describe OpenProject::XlsExport::XlsViews do
  subject(:view) { described_class.new }

  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:work_package) do
    create(:work_package, project:, type:, subject: "Fix the thing").tap do |wp|
      wp.update_columns(identifier: "PROJ-42", sequence_number: 42)
    end
  end

  # The "Logged for" cell is the entity_gid attribute; the renderer locates the
  # work package from its GlobalID and formats "<type> <id>: <subject>".
  describe "#entity_global_id_representation" do
    let(:entity_gid) { work_package.to_global_id.to_s }

    context "with semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "renders the semantic identifier, not the numeric id" do
        expect(view.entity_global_id_representation(entity_gid))
          .to eq("Task PROJ-42: Fix the thing")
      end
    end

    context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "renders the numeric id with a # prefix (no regression)" do
        expect(view.entity_global_id_representation(entity_gid))
          .to eq("Task ##{work_package.id}: Fix the thing")
      end
    end
  end

  # The :work_package_id column renderer is fed the numeric id directly and
  # formats "<type> <id>: <subject>"; it must honour the same display identifier.
  describe "#work_package_representation" do
    context "with semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "renders the semantic identifier, not the numeric id" do
        expect(view.work_package_representation(work_package.id))
          .to eq("Task PROJ-42: Fix the thing")
      end
    end

    context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "renders the numeric id with a # prefix (no regression)" do
        expect(view.work_package_representation(work_package.id))
          .to eq("Task ##{work_package.id}: Fix the thing")
      end
    end
  end
end
