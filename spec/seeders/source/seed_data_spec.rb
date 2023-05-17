# frozen_string_literal: true

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

RSpec.describe Source::SeedData do
  subject(:seed_data) { described_class.new({}) }

  describe '#store_reference / find_reference' do
    it 'acts as a key store to register object by a symbol' do
      object = Object.new
      seed_data.store_reference(:ref, object)
      expect(seed_data.find_reference(:ref)).to be(object)
    end

    it 'stores nothing if reference is nil' do
      object = Object.new
      seed_data.store_reference(nil, object)
      seed_data.store_reference(nil, object)
    end

    it 'returns nil if reference is nil' do
      expect(seed_data.find_reference(nil)).to be_nil
      object = Object.new
      seed_data.store_reference(nil, object)
      expect(seed_data.find_reference(nil)).to be_nil
    end

    it 'raises an error when the reference is already used' do
      seed_data.store_reference(:ref, Object.new)
      expect { seed_data.store_reference(:ref, Object.new) }
        .to raise_error(ArgumentError)
    end
  end
end
