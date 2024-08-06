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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe "MeetingMinutes" do
  before do
    @min = build(:meeting_minutes)
  end

  # meeting minutes are editable when the meeting agenda is locked
  describe "#editable?" do
    before do
      @mee = build(:meeting)
      @min.meeting = @mee
    end

    describe "with no agenda present" do
      it "is not editable" do
        expect(@min.editable?).to be_falsey
      end
    end

    describe "with an agenda present" do
      before do
        @a = build(:meeting_agenda)
        @mee.agenda = @a
      end

      it "is not editable when the agenda is open" do
        expect(@min.editable?).to be_falsey
      end

      it "is editable when the agenda is closed" do
        @a.lock!
        expect(@min.editable?).to be_truthy
      end
    end
  end
end
