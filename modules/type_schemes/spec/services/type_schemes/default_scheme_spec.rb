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

RSpec.describe TypeSchemes::DefaultScheme do
  let!(:epic) { create(:type, name: "Epic", position: 1) }
  let!(:task) { create(:type, name: "Task", position: 2) }
  let!(:milestone) { create(:type, name: "Milestone", position: 3, is_milestone: true) }

  describe ".ensure!" do
    it "creates an active default scheme with all types and Task as default type" do
      scheme = described_class.ensure!

      expect(scheme).to be_persisted.and be_is_default.and be_active
      expect(scheme.types).to include(epic, task, milestone)
      expect(scheme.default_type).to eq task
    end

    it "is idempotent" do
      expect { 2.times { described_class.ensure! } }.to change(TypeScheme, :count).by(1)
    end

    it "matches the task type case-insensitively" do
      task.update!(name: "TASK")
      expect(described_class.ensure!.default_type).to eq task
    end

    it "falls back to the first non-milestone type when there is no Task" do
      task.destroy
      expect(described_class.ensure!.default_type).to eq epic
    end
  end

  describe ".add_type" do
    it "appends a new type to the default scheme without making it default" do
      scheme = described_class.ensure!
      added = create(:type, name: "Spike")

      expect(scheme.reload.types).to include(added)
      expect(scheme.default_type).to eq task
    end

    it "does nothing without a default scheme" do
      expect { create(:type, name: "Spike") }.not_to change(TypeSchemeItem, :count)
    end
  end
end
