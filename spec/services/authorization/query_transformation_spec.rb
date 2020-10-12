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

describe Authorization::QueryTransformation do
  let(:on) { 'on' }
  let(:name) { 'name' }
  let(:after) { 'after' }
  let(:before) { 'before' }
  let(:block) { -> (*args) { args } }

  let(:instance) do
    described_class.new on,
                        name,
                        after,
                        before,
                        block
  end

  context 'initialSetup' do
    it 'sets on' do
      expect(instance.on).to eql on
    end

    it 'sets name' do
      expect(instance.name).to eql name
    end

    it 'sets after' do
      expect(instance.after).to eql after
    end

    it 'sets before' do
      expect(instance.before).to eql before
    end

    it 'sets block' do
      expect(instance.block).to eql block
    end
  end

  context 'apply' do
    it 'calls the block' do
      expect(instance.apply(1, 2, 3)).to match_array [1, 2, 3]
    end
  end
end
