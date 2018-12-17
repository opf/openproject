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

FactoryBot.define do
  factory :meeting_journal do
    created_at { Time.now }
    sequence(:version) { |n| n }

    factory :meeting_content_journal, class: Journal do
      journable_type { 'MeetingContent' }
      activity_type { 'meetings' }
      data { FactoryBot.build(:journal_meeting_content_journal) }
    end
  end
end
