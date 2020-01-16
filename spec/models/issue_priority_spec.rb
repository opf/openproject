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

describe IssuePriority, type: :model do
  let(:stubbed_priority) { FactoryBot.build_stubbed(:priority) }
  let(:priority) { FactoryBot.create(:priority) }

  describe '.ancestors' do
    it 'is an enumeration' do
      expect(IssuePriority.ancestors)
        .to include(Enumeration)
    end
  end

  describe '#objects_count' do
    let(:work_package1) { FactoryBot.create(:work_package, priority: priority) }
    let(:work_package2) { FactoryBot.create(:work_package) }

    it 'counts the work packages having the priority' do
      expect(priority.objects_count)
        .to eql 0

      work_package1
      work_package2

      # will not count the other work package
      expect(priority.objects_count)
        .to eql 1
    end
  end

  describe '#option_name' do
    it 'is a symbol' do
      expect(stubbed_priority.option_name)
        .to eql :enumeration_work_package_priorities
    end
  end

  describe '#cache_key' do
    it 'updates when the updated_at field changes' do
      old_cache_key = stubbed_priority.cache_key

      stubbed_priority.updated_at = Time.now

      expect(stubbed_priority.cache_key)
        .not_to eql old_cache_key
    end
  end

  describe '#transer_to' do
    let(:new_priority) { FactoryBot.create(:priority) }
    let(:work_package1) { FactoryBot.create(:work_package, priority: priority) }
    let(:work_package2) { FactoryBot.create(:work_package) }
    let(:work_package3) { FactoryBot.create(:work_package, priority: new_priority) }

    it 'moves all work_packages to the designated priority' do
      work_package1
      work_package2
      work_package3

      priority.transfer_relations(new_priority)

      expect(new_priority.work_packages.reload)
        .to match_array [work_package3, work_package1]
    end
  end
end
