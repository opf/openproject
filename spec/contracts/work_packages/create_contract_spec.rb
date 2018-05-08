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

require 'spec_helper'

describe WorkPackages::CreateContract do
  let(:work_package) do
    FactoryBot.build(:work_package,
                      author: member,
                      project: project)
  end
  let(:member) {
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  }
  let (:project) { FactoryBot.create(:project) }
  let(:current_user) { member }
  let(:permissions) {
    [
      :view_work_packages,
      :add_work_packages
    ]
  }
  let(:role) { FactoryBot.create :role, permissions: permissions }
  let(:changed_values) { [] }

  subject(:contract) { described_class.new(work_package, current_user) }

  before do
    allow(work_package).to receive(:changed).and_return(changed_values)
  end

  describe 'story points' do
    context 'has not changed' do
      it('is valid') { expect(contract.errors.empty?).to be true }
    end

    context 'has changed' do
      let(:changed_values) { ['story_points'] }

      it('is valid') { expect(contract.errors.empty?).to be true }
    end
  end

  describe 'remaining hours' do
    context 'is no parent' do
      before do
        contract.validate
      end

      context 'has not changed' do
        it('is valid') { expect(contract.errors.empty?).to be true }
      end

      context 'has changed' do
        let(:changed_values) { ['remaining_hours'] }

        it('is valid') { expect(contract.errors.empty?).to be true }
      end
    end
  end
end
