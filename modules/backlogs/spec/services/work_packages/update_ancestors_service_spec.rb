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
