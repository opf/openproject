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

RSpec.describe API::V3::RecurringMeetings::RecurringMeetingRepresenter do
  let(:project) { build_stubbed(:project) }
  let(:current_user) { build_stubbed(:user) }
  let(:template) { build_stubbed(:meeting, project:, notify: true) }
  let(:recurring_meeting) do
    build_stubbed(:recurring_meeting, project:, author: current_user).tap do |rm|
      allow(rm).to receive(:template).and_return(template)
    end
  end
  let(:representer) { described_class.new(recurring_meeting, current_user:) }

  describe "#json_cache_key" do
    it "changes when the template changes" do
      key_before = representer.json_cache_key

      template.updated_at = template.updated_at + 1.hour

      expect(representer.json_cache_key).not_to eql key_before
    end
  end
end
