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

require "rails_helper"

RSpec.describe Admin::Import::Jira::ImportRuns::BatchStatusComponent, type: :component do
  subject(:component) { described_class.new(batch: nil) }

  def job(*arguments)
    instance_double(GoodJob::Job, serialized_params: { "arguments" => arguments })
  end

  describe "#remaining_projects_count" do
    it "counts the projects of a stage that have no job on display" do
      jobs = [job(1, 10), job(1, 10), job(1, 11), job(1, 12), job(1, 12)]

      expect(component.remaining_projects_count(jobs, jobs.first(4))).to eq(0)
      expect(component.remaining_projects_count(jobs, jobs.first(2))).to eq(2)
    end

    it "counts a project once however many jobs of it are left" do
      jobs = [job(1, 10), job(1, 10), job(1, 10)]

      expect(component.remaining_projects_count(jobs, [])).to eq(1)
    end

    it "ignores jobs that run for the whole import rather than one project" do
      jobs = [job(1), job(1, 10)]

      expect(component.remaining_projects_count(jobs, [])).to eq(1)
      expect(component.remaining_projects_count(jobs, [jobs.second])).to eq(0)
    end
  end
end
