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

RSpec.describe JobConcurrency do
  let(:job_class) do
    Class.new(ApplicationJob) do
      include JobConcurrency

      def self.name
        "JobConcurrencyTestJob"
      end

      good_job_control_concurrency_with(total_limit: 1)

      def perform; end
    end
  end

  let(:concurrency_key) { "JobConcurrencyTestJob" }
  let(:relation) { double("GoodJob::Job::ActiveRecord_Relation") } # rubocop:disable RSpec/VerifiedDoubles
  let(:unfinished) { double("unfinished relation") } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(GoodJob::Job).to receive(:where).with(concurrency_key:).and_return(relation)
    allow(relation).to receive(:unfinished).and_return(unfinished)
  end

  describe "#check_concurrency" do
    subject(:check) do
      called = false
      job = job_class.new
      allow(job).to receive(:good_job_concurrency_key).and_return(concurrency_key)
      job.check_concurrency { called = true }
      called
    end

    it "counts all unfinished jobs including ones currently performing" do
      expect(unfinished).to receive(:count).and_return(1)
      expect(unfinished).not_to receive(:advisory_unlocked)

      expect(check).to be true
    end

    it "does not yield when below the limit" do
      expect(unfinished).to receive(:count).and_return(0)

      expect(check).to be false
    end
  end
end
