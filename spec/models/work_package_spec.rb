#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
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

describe WorkPackage, type: :model do
  describe '#backlogs_types' do
    it 'should return all the ids of types that are configures to be considered backlogs types' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [1], 'task_type' => 2 })

      expect(WorkPackage.backlogs_types).to match_array([1, 2])
    end

    it 'should return an empty array if nothing is defined' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({})

      expect(WorkPackage.backlogs_types).to eq([])
    end

    it 'should reflect changes to the configuration' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [1], 'task_type' => 2 })
      expect(WorkPackage.backlogs_types).to match_array([1, 2])

      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [3], 'task_type' => 4 })
      expect(WorkPackage.backlogs_types).to match_array([3, 4])
    end
  end
end
