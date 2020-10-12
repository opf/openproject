#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../spec_helper'

describe 'MeetingMinutes', type: :model do
  before do
    @min = FactoryBot.build :meeting_minutes
  end

  # meeting minutes are editable when the meeting agenda is locked
  describe '#editable?' do
    before(:each) do
      @mee = FactoryBot.build :meeting
      @min.meeting = @mee
    end
    describe 'with no agenda present' do
      it 'is not editable' do
        expect(@min.editable?).to be_falsey
      end
    end
    describe 'with an agenda present' do
      before(:each) do
        @a = FactoryBot.build :meeting_agenda
        @mee.agenda = @a
      end
      it 'is not editable when the agenda is open' do
        expect(@min.editable?).to be_falsey
      end
      it 'is editable when the agenda is closed' do
        @a.lock!
        expect(@min.editable?).to be_truthy
      end
    end
  end
end
