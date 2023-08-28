#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe WorkPackages::UpdateAncestorsService do
  let(:user) { create(:user) }

  let(:sibling_remaining_hours) { 7.0 }
  let(:parent_remaining_hours) { 2.0 }
  let(:work_package_remaining_hours) { 5.0 }

  let!(:grandparent) { create(:work_package) }
  let!(:parent) { create(:work_package, parent: grandparent, remaining_hours: parent_remaining_hours) }
  let!(:sibling) { create(:work_package, parent:, remaining_hours: sibling_remaining_hours) }

  context 'for a new ancestors' do
    let!(:work_package) { create(:work_package, remaining_hours: work_package_remaining_hours, parent:) }

    before do
      described_class.new(user:, work_package:).call(%i(parent))
    end

    it 'recalculates the remaining_hours for new parent and grandparent' do
      [grandparent, parent, sibling].each(&:reload)

      expect(grandparent.remaining_hours).to be_nil
      expect(grandparent.derived_remaining_hours)
        .to eql(sibling_remaining_hours + work_package_remaining_hours + parent_remaining_hours)

      expect(parent.remaining_hours).to eql(parent_remaining_hours)
      expect(parent.derived_remaining_hours).to eql(sibling_remaining_hours + work_package_remaining_hours)

      expect(sibling.remaining_hours).to eql(sibling_remaining_hours)
      expect(sibling.derived_remaining_hours).to be_nil

      expect(work_package.remaining_hours).to eql(work_package_remaining_hours)
      expect(work_package.derived_remaining_hours).to be_nil
    end
  end

  context 'for the previous ancestors' do
    let(:work_package) { create(:work_package, remaining_hours: work_package_remaining_hours, parent:) }

    before do
      work_package.parent = nil
      work_package.save!

      described_class.new(user:, work_package:).call(%i(parent))
    end

    it 'recalculates the derived_remaining_hours for former parent and grandparent' do
      [grandparent, parent, sibling, work_package].each(&:reload)

      expect(grandparent.remaining_hours).to be_nil
      expect(grandparent.derived_remaining_hours).to eql sibling_remaining_hours + parent_remaining_hours

      expect(parent.remaining_hours).to eql(parent_remaining_hours)
      expect(parent.derived_remaining_hours).to eql sibling_remaining_hours

      expect(sibling.remaining_hours).to eql sibling_remaining_hours
      expect(sibling.derived_remaining_hours).to be_nil

      expect(work_package.remaining_hours).to eql work_package_remaining_hours
      expect(work_package.derived_remaining_hours).to be_nil
    end
  end
end
