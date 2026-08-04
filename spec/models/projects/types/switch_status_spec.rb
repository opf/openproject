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

RSpec.describe Projects::Types::SwitchStatus do
  shared_let(:user) { create(:admin) }
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }

  let(:project) { create(:project, types: [epic]) }

  def create_status(status:, kind: "type_switch", for_project: project)
    JobStatus::Status.create!(
      job_id: SecureRandom.uuid,
      user:,
      status:,
      message: "The project now uses Epic: Design.",
      payload: { "kind" => kind, "project_id" => for_project.id, "source_id" => epic.id, "target_id" => design.id }
    )
  end

  describe ".pending_for" do
    it "finds a queued switch" do
      create_status(status: :in_queue)

      expect(described_class.pending_for(project).target).to eq(design)
    end

    it "finds a running switch" do
      create_status(status: :in_process)

      expect(described_class.pending_for(project)).to be_present
    end

    it "ignores a settled switch" do
      create_status(status: :success)

      expect(described_class.pending_for(project)).to be_nil
    end

    it "ignores another project's switch" do
      create_status(status: :in_process, for_project: create(:project))

      expect(described_class.pending_for(project)).to be_nil
    end

    # A project is switched repeatedly, so its rows accumulate.
    it "finds the running switch even when earlier ones have settled" do
      create_status(status: :success)
      create_status(status: :in_process)

      expect(described_class.pending_for(project)).to be_present
    end

    # A status row referencing a project need not be ours: the discriminator is
    # what keeps another job's row from painting the type list.
    it "ignores a row from a different kind of job" do
      create_status(status: :in_process, kind: "something_else")

      expect(described_class.pending_for(project)).to be_nil
    end
  end

  describe ".latest_for" do
    it "reports the outcome of the switch that just settled" do
      create_status(status: :success)

      expect(described_class.latest_for(project)).to be_success
    end

    it "reports a failure as such" do
      create_status(status: :failure)

      expect(described_class.latest_for(project)).not_to be_success
    end

    it "is nil when the project has never had one" do
      expect(described_class.latest_for(project)).to be_nil
    end
  end

  describe "#source_id" do
    it "names the row the switch belongs to" do
      create_status(status: :in_process)

      expect(described_class.pending_for(project).source_id).to eq(epic.id)
    end
  end

  describe "#message" do
    it "carries what the job reported, for the page to announce" do
      create_status(status: :success)

      expect(described_class.latest_for(project).message).to eq("The project now uses Epic: Design.")
    end
  end
end
