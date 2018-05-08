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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe WorkPackages::UpdateAncestorsService do
  let(:user) { FactoryBot.create :user }

  let(:sibling_remaining_hours) { 7.0 }
  let(:work_package_remaining_hours) { 5.0 }

  let!(:grandparent) do
    FactoryBot.create :work_package
  end
  let!(:parent) do
    FactoryBot.create :work_package,
                       parent: grandparent
  end
  let!(:sibling) do
    FactoryBot.create :work_package,
                       parent: parent,
                       remaining_hours: sibling_remaining_hours
  end

  context 'for a new ancestors' do
    let!(:work_package) do
      FactoryBot.create :work_package,
                         remaining_hours: work_package_remaining_hours,
                         parent: parent
    end

    subject do
      described_class
        .new(user: user,
             work_package: work_package)
        .call(%i(parent))
    end

    before do
      subject
    end

    it 'recalculates the remaining_hours for new parent and grandparent' do
      expect(grandparent.reload.remaining_hours)
        .to eql sibling_remaining_hours + work_package_remaining_hours

      expect(parent.reload.remaining_hours)
        .to eql sibling_remaining_hours + work_package_remaining_hours

      expect(sibling.reload.remaining_hours)
        .to eql sibling_remaining_hours

      expect(work_package.reload.remaining_hours)
        .to eql work_package_remaining_hours
    end
  end

  context 'for the previous ancestors' do
    let!(:work_package) do
      FactoryBot.create :work_package,
                         remaining_hours: work_package_remaining_hours,
                         parent: parent
    end

    subject do
      work_package.parent = nil
      work_package.save!

      described_class
        .new(user: user,
             work_package: work_package)
        .call(%i(parent))
    end

    before do
      subject
    end

    it 'recalculates the remaining_hours for former parent and grandparent' do
      expect(grandparent.reload.remaining_hours)
        .to eql sibling_remaining_hours

      expect(parent.reload.remaining_hours)
        .to eql sibling_remaining_hours

      expect(sibling.reload.remaining_hours)
        .to eql sibling_remaining_hours

      expect(work_package.reload.remaining_hours)
        .to eql work_package_remaining_hours
    end
  end
end
