#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  describe 'backlogs_preference' do
    describe 'task_color' do
      it 'reads from and writes to a user preference' do
        u = FactoryGirl.create(:user)
        u.backlogs_preference(:task_color, '#FFCC33')

        u.backlogs_preference(:task_color).should == '#FFCC33'
        u.reload
        u.backlogs_preference(:task_color).should == '#FFCC33'
      end

      it 'computes a random color and persists it, when none is set' do
        u = FactoryGirl.create(:user)
        u.backlogs_preference(:task_color, nil)
        u.save!

        generated_task_color = u.backlogs_preference(:task_color)
        generated_task_color.should =~ /^#[0-9A-F]{6}$/
        u.save!
        u.reload
        u.backlogs_preference(:task_color).should == generated_task_color
      end
    end
  end
end
