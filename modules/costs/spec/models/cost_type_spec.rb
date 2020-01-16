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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CostType, type: :model do
  let(:klass) { CostType }
  let(:cost_type) {
    klass.new name: 'ct1',
              unit: 'singular',
              unit_plural: 'plural'
  }
  before do
    # as the spec_helper loads fixtures and they are probably needed by other tests
    # we delete them here so they do not interfere.
    # on the long run, fixtures should be removed

    CostType.destroy_all
  end

  describe 'class' do
    describe 'active' do
      describe 'WHEN a CostType instance is deleted' do
        before do
          cost_type.deleted_at = Time.now
          cost_type.save!
        end

        it { expect(klass.active.size).to eq(0) }
      end

      describe 'WHEN a CostType instance is not deleted' do
        before do
          cost_type.save!
        end

        it { expect(klass.active.size).to eq(1) }
        it { expect(klass.active[0]).to eq(cost_type) }
      end
    end
  end
end
