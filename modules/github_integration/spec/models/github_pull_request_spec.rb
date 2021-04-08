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

    describe 'draft' do
      it { is_expected.to allow_value(true).for(:draft) }
      it { is_expected.to allow_value(false).for(:draft) }
      it { is_expected.to allow_value(nil).for(:draft) }
    end

    describe 'merged' do
      it { is_expected.to allow_value(true).for(:merged) }
      it { is_expected.to allow_value(false).for(:merged) }
      it { is_expected.to allow_value(nil).for(:merged) }
    end

    describe 'state' do
      it { is_expected.to allow_value('open').for(:state) }
      it { is_expected.to allow_value('closed').for(:state) }
      it { is_expected.to allow_value('partial').for(:state) }
      it { is_expected.not_to allow_value(:something_else).for(:state) }
    end

    describe 'labels' do
      it { is_expected.to allow_value(nil).for(:labels) }
      it { is_expected.to allow_value([]).for(:labels) }
      it { is_expected.to allow_value([{ 'color' => '#666', 'name' => 'grey' }]).for(:labels) }
      it { is_expected.not_to allow_value([{ 'name' => 'grey' }]).for(:labels) }
      it { is_expected.not_to allow_value([{}]).for(:labels) }
    end
  end

  describe '.partial?' do
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
end
