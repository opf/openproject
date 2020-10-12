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

describe Authorization::QueryTransformations do
  let(:instance) { described_class.new }

  context 'registering a transformation' do
    before do
      instance.register(:on, :name) do |*args|
        args
      end
    end

    context '#for?' do
      it 'is true for the registered name' do
        expect(instance.for?(:on)).to be_truthy
      end

      it 'is false for another name' do
        expect(instance.for?(:other_name)).to be_falsey
      end
    end

    context '#for' do
      it 'returns an array of transformations for the registered name' do
        expect(instance.for(:on).length).to eql 1

        expect(instance.for(:on)[0].on).to eql :on
        expect(instance.for(:on)[0].name).to eql :name
        expect(instance.for(:on)[0].block.call(1, 2, 3)).to match_array [1, 2, 3]
      end

      it 'is nil for another name' do
        expect(instance.for(:other_name)).to be_nil
      end
    end
  end

  context 'registering two transformations depending via after' do
    before do
      instance.register(:on, :transformation1, after: [:transformation2]) do |*args|
        args
      end

      instance.register(:on, :transformation2) do |*args|
        args.join(', ')
      end
    end

    context '#for?' do
      it 'is true for the registered name' do
        expect(instance.for?(:on)).to be_truthy
      end

      it 'is false for another name' do
        expect(instance.for?(:other_name)).to be_falsey
      end
    end

    context '#for' do
      it 'returns an array of transformations for the registered name' do
        expect(instance.for(:on).length).to eql 2

        expect(instance.for(:on)[0].on).to eql :on
        expect(instance.for(:on)[0].name).to eql :transformation2
        expect(instance.for(:on)[0].block.call(1, 2, 3)).to eql '1, 2, 3'

        expect(instance.for(:on)[1].on).to eql :on
        expect(instance.for(:on)[1].name).to eql :transformation1
        expect(instance.for(:on)[1].block.call(1, 2, 3)).to match_array [1, 2, 3]
      end
    end
  end

  context 'registering two transformations depending via before' do
    before do
      instance.register(:on, :transformation1) do |*args|
        args
      end

      instance.register(:on, :transformation2, before: [:transformation1]) do |*args|
        args.join(', ')
      end
    end

    context '#for?' do
      it 'is true for the registered name' do
        expect(instance.for?(:on)).to be_truthy
      end

      it 'is false for another name' do
        expect(instance.for?(:other_name)).to be_falsey
      end
    end

    context '#for' do
      it 'returns an array of transformations for the registered name' do
        expect(instance.for(:on).length).to eql 2

        expect(instance.for(:on)[0].on).to eql :on
        expect(instance.for(:on)[0].name).to eql :transformation2
        expect(instance.for(:on)[0].block.call(1, 2, 3)).to eql '1, 2, 3'

        expect(instance.for(:on)[1].on).to eql :on
        expect(instance.for(:on)[1].name).to eql :transformation1
        expect(instance.for(:on)[1].block.call(1, 2, 3)).to match_array [1, 2, 3]
      end
    end
  end

  context 'registering two mutually dependent transformations' do
    it 'fails' do
      instance.register(:on, :transformation1, before: [:transformation2]) do |*args|
        args
      end

      expected_order = [:transformation1, :transformation2]

      expect {
        instance.register(:on, :transformation2, before: [:transformation1]) do |*args|
          args.join(', ')
        end
      }.to raise_error "Cannot sort #{expected_order} into the list of transformations"
    end
  end
end
