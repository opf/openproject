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
require "#{File.dirname(__FILE__)}/../spec_helper"

describe GithubPullRequest do
  describe "validations" do
    it { is_expected.to validate_presence_of :github_html_url }
    it { is_expected.to validate_presence_of :number }
    it { is_expected.to validate_presence_of :repository }
    it { is_expected.to validate_presence_of :state }

    context 'when it is not a partial pull request' do
      subject { described_class.new(state: 'open') }

      it { is_expected.to validate_presence_of :github_updated_at }
      it { is_expected.to validate_presence_of :title }
      it { is_expected.to validate_presence_of :body }
      it { is_expected.to validate_presence_of :comments_count }
      it { is_expected.to validate_presence_of :review_comments_count }
      it { is_expected.to validate_presence_of :additions_count }
      it { is_expected.to validate_presence_of :deletions_count }
      it { is_expected.to validate_presence_of :changed_files_count }
    end

    describe 'labels' do
      it { is_expected.to allow_value(nil).for(:labels) }
      it { is_expected.to allow_value([]).for(:labels) }
      it { is_expected.to allow_value([{ 'color' => '#666', 'name' => 'grey' }]).for(:labels) }
      it { is_expected.not_to allow_value([{ 'name' => 'grey' }]).for(:labels) }
      it { is_expected.not_to allow_value([{}]).for(:labels) }
    end
  end

  describe '.complete' do
    subject { described_class.complete }

    let(:open) { FactoryBot.create(:github_pull_request, :open) }
    let(:merged) { FactoryBot.create(:github_pull_request, :closed_merged) }
    let(:closed) { FactoryBot.create(:github_pull_request, :closed_unmerged) }
    let(:partial) { FactoryBot.create(:github_pull_request, :partial) }
    let(:all_pull_requests) { [open, merged, closed, partial] }

    before { all_pull_requests }

    it { is_expected.to match_array [open, merged, closed] }
  end

  describe '.without_work_package' do
    subject { described_class.without_work_package }

    let(:pull_request) { FactoryBot.create(:github_pull_request, work_packages: work_packages) }
    let(:work_packages) { [] }

    before { pull_request }

    it { is_expected.to match_array([pull_request]) }

    context 'when the pr is linked to a work_package' do
      let(:work_packages) { FactoryBot.create_list(:work_package, 1) }

      it { is_expected.to be_empty }
    end
  end

  describe '#partial?' do
    context 'when the state is partial' do
      subject { described_class.new(state: 'partial').partial? }

      it { is_expected.to be true }
    end

    context 'when the state is open' do
      subject { described_class.new(state: 'open').partial? }

      it { is_expected.to be false }
    end

    context 'when the state is closed' do
      subject { described_class.new(state: 'closed').partial? }

      it { is_expected.to be false }
    end
  end

  describe '#latest_check_runs' do
    subject { pull_request.reload.latest_check_runs }

    let(:pull_request) { FactoryBot.create(:github_pull_request) }

    it { is_expected.to be_empty }

    context 'when multiple check_runs from different apps with different names exist' do
      let(:latest_check_runs) do
        [
          FactoryBot.create(
            :github_check_run,
            app_id: 123,
            name: 'test',
            started_at: 1.minute.ago,
            github_pull_request: pull_request
          ),
          FactoryBot.create(
            :github_check_run,
            app_id: 123,
            name: 'lint',
            started_at: 1.minute.ago,
            github_pull_request: pull_request
          ),
          FactoryBot.create(
            :github_check_run,
            app_id: 456,
            name: 'test',
            started_at: 1.minute.ago,
            github_pull_request: pull_request
          ),
          FactoryBot.create(
            :github_check_run,
            app_id: 789,
            name: 'test',
            started_at: 1.minute.ago,
            github_pull_request: pull_request
          )
        ]
      end
      let(:outdated_check_runs) do
        [
          FactoryBot.create(
            :github_check_run,
            app_id: 123,
            name: 'test',
            started_at: 2.minutes.ago,
            github_pull_request: pull_request
          ),
          FactoryBot.create(
            :github_check_run,
            app_id: 123,
            name: 'test',
            started_at: 3.minutes.ago,
            github_pull_request: pull_request
          ),
          FactoryBot.create(
            :github_check_run,
            app_id: 123,
            name: 'lint',
            started_at: 5.minutes.ago,
            github_pull_request: pull_request
          )
        ]
      end
      let(:check_runs) { latest_check_runs + outdated_check_runs }

      before { check_runs }

      it { is_expected.to match_array(latest_check_runs) }
    end
  end
end
