#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe 'MeetingAgenda', type: :model do
  before(:each) do
    @a = FactoryBot.build :meeting_agenda, text: "Some content...\n\nMore content!\n\nExtraordinary content!!"
  end

  # TODO: Test the right user and messages are set in the history
  describe '#lock!' do
    it 'locks the agenda' do
      @a.save
      @a.reload
      @a.lock!
      @a.reload
      expect(@a.locked).to be_truthy
    end
  end

  describe '#unlock!' do
    it 'unlocks the agenda' do
      @a.locked = true
      @a.save
      @a.reload
      @a.unlock!
      @a.reload
      expect(@a.locked).to be_falsey
    end
  end

  # a meeting agenda is editable when it is not locked
  describe '#editable?' do
    it 'is editable when not locked' do
      @a.locked = false
      expect(@a.editable?).to be_truthy
    end
    it 'is not editable when locked' do
      @a.locked = true
      expect(@a.editable?).to be_falsey
    end
  end
end
