#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Cron::ClearOldPullRequestsJob, type: :job do
  let(:pull_request_without_work_package) do
    FactoryBot.create(:github_pull_request, work_packages: [])
  end
  let(:pull_request_with_work_package) { FactoryBot.create(:github_pull_request, work_packages: [work_package]) }
  let(:work_package) { FactoryBot.create(:work_package) }
  let(:check_run) { FactoryBot.create(:github_check_run, github_pull_request: pull_request_without_work_package) }

  let(:job) { described_class.new }

  before do
    pull_request_without_work_package
    check_run
    pull_request_with_work_package
  end

  it 'removes pull request without work packages attached' do
    expect { job.perform }.to change(GithubPullRequest, :count).by(-1).and(change(GithubCheckRun, :count).by(-1))

    expect(GithubPullRequest.all)
      .to match_array([pull_request_with_work_package])
  end
end
