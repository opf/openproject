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

require "rails_helper"

RSpec.describe ProjectIdentifiers::ConvertInstanceToSemanticIdsJob,
               with_good_job_batches: [
                 ProjectIdentifiers::FinishSemanticConversionJob,
                 ProjectIdentifiers::ConvertProjectToSemanticIdsJob
               ] do
  subject(:job) { described_class.new }

  describe "#perform" do
    context "when there are projects to convert" do
      before { allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set[1, 2]) }

      it "enqueues one ConvertProjectToSemanticIdsJob per pending project" do
        job.perform
        expect(GoodJob::Job.where(job_class: ProjectIdentifiers::ConvertProjectToSemanticIdsJob.name).count).to eq(2)
      end

      it "sets FinishSemanticConversionJob as the on_finish callback" do
        allow(GoodJob::Batch).to receive(:enqueue).and_call_original
        job.perform
        expect(GoodJob::Batch).to have_received(:enqueue)
          .with(hash_including(on_finish: ProjectIdentifiers::FinishSemanticConversionJob))
      end
    end

    context "when there are no projects to convert" do
      before { allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set.new) }

      it "does not enqueue any per-project jobs" do
        job.perform
        expect(GoodJob::Job.where(job_class: ProjectIdentifiers::ConvertProjectToSemanticIdsJob.name)).not_to exist
      end
    end
  end
end
