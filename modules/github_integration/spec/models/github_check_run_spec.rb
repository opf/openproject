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

describe GithubCheckRun do
  describe "validations" do
    it { is_expected.to validate_presence_of :github_app_owner_avatar_url }
    it { is_expected.to validate_presence_of :github_html_url }
    it { is_expected.to validate_presence_of :github_id }
    it { is_expected.to validate_presence_of :status }

    describe 'status' do
      it { is_expected.to allow_value('queued').for(:status) }
      it { is_expected.to allow_value('in_progress').for(:status) }
      it { is_expected.to allow_value('completed').for(:status) }
      it { is_expected.not_to allow_value(:something_else).for(:status) }
    end

    describe 'conclusion' do
      it { is_expected.to allow_value('action_required').for(:conclusion) }
      it { is_expected.to allow_value('cancelled').for(:conclusion) }
      it { is_expected.to allow_value('failure').for(:conclusion) }
      it { is_expected.to allow_value('neutral').for(:conclusion) }
      it { is_expected.to allow_value('success').for(:conclusion) }
      it { is_expected.to allow_value('skipped').for(:conclusion) }
      it { is_expected.to allow_value('stale').for(:conclusion) }
      it { is_expected.to allow_value('timed_out').for(:conclusion) }
      it { is_expected.to allow_value(nil).for(:conclusion) }
      it { is_expected.not_to allow_value('').for(:conclusion) }
      it { is_expected.not_to allow_value(:something_else).for(:conclusion) }
    end
  end
end
