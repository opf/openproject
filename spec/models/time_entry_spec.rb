#-- encoding: UTF-8

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

require 'spec_helper'

describe TimeEntry, type: :model do
  describe '#hours' do
    formats = { '2' => 2.0,
                '21.1' => 21.1,
                '2,1' => 2.1,
                '1,5h' => 1.5,
                '7:12' => 7.2,
                '10h' => 10.0,
                '10 h' => 10.0,
                '45m' => 0.75,
                '45 m' => 0.75,
                '3h15' => 3.25,
                '3h 15' => 3.25,
                '3 h 15' => 3.25,
                '3 h 15m' => 3.25,
                '3 h 15 m' => 3.25,
                '3 hours' => 3.0,
                '12min' => 0.2 }

    formats.each do |from, to|
      it "formats '#{from}'" do
        t = TimeEntry.new(hours: from)
        expect(t.hours)
          .to eql to
      end
    end
  end
end
