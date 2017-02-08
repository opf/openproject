#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::AvailableFilters, type: :model do
  let(:context) { FactoryGirl.build_stubbed(:project) }
  let(:register) { Queries::FilterRegister }

  class HelperClass
    attr_accessor :context

    def initialize(context)
      self.context = context
    end

    include Queries::AvailableFilters
  end

  let(:includer) do
    includer = HelperClass.new(context)

    allow(Queries::Register)
      .to receive(:filters)
      .and_return(HelperClass => registered_filters)

    includer
  end

  describe '#filter_for' do
    let(:filter_1_available) { true }
    let(:filter_2_available) { true }
    let(:filter_1_key) { :filter_1 }
    let(:filter_2_key) { /f_\d+/ }
    let(:filter_1_name) { :filter_1 }
    let(:filter_2_name) { :f_1 }
    let(:registered_filters) { [filter_1, filter_2] }

    let(:filter_1_instance) do
      instance = double("filter_1_instance")

      allow(instance)
        .to receive(:available?)
        .and_return(:filter_1_available)

      allow(instance)
        .to receive(:name)
        .and_return(:filter_1)

      allow(instance)
        .to receive(:name=)

      instance
    end

    let(:filter_1) do
      filter = double('filter_1')

      allow(filter)
        .to receive(:key)
        .and_return(:filter_1)

      allow(filter)
        .to receive(:new)
        .and_return(filter_1_instance)

      allow(filter)
        .to receive(:all_for)
        .with(context)
        .and_return(filter_1_instance)

      filter
    end

    let(:filter_2_instance) do
      instance = double("filter_2_instance")

      allow(instance)
        .to receive(:available?)
        .and_return(:filter_2_available)

      allow(instance)
        .to receive(:name)
        .and_return(:f_1)

      allow(instance)
        .to receive(:name=)

      instance
    end

    let(:filter_2) do
      filter = double('filter_2')

      allow(filter)
        .to receive(:key)
        .and_return(/f_\d+/)

      allow(filter)
        .to receive(:all_for)
        .with(context)
        .and_return(filter_2_instance)

      filter
    end

    context 'for a filter identified by a symbol' do
      let(:filter_3_available) { true }
      let(:registered_filters) { [filter_3, filter_1, filter_2] }

      # As we use regexp to find the filters
      # we have to ensure that a filter identified a substring symbol
      # is not accidentally found
      let(:filter_3) do
        instance = double('filter_3_instance')

        allow(instance)
          .to receive(:available?)
          .and_return(filter_3_available)

        filter = double('filter_3')

        allow(filter)
          .to receive(:key)
          .and_return(:filter)

        allow(filter)
          .to receive(:all_for)
          .with(context)
          .and_return(instance)

        filter
      end

      context 'if available' do
        let(:filter_3_available) { false }

        it 'returns an instance of the matching filter' do
          expect(includer.filter_for(:filter_1)).to eql filter_1_instance
        end

        it 'returns the NotExistingFilter if the name is not matched' do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::NotExistingFilter
        end
      end

      context 'if not available' do
        let(:filter_1_available) { false }
        let(:filter_3_available) { true }

        it 'returns the NotExistingFilter if the name is not matched' do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::NotExistingFilter
        end

        it 'returns an instance of the matching filter if not caring for availablility' do
          expect(includer.filter_for(:filter_1, true)).to eql filter_1_instance
        end
      end
    end

    context 'for a filter identified by a regexp' do
      context 'if available' do
        it 'returns an instance of the matching filter' do
          expect(includer.filter_for(:f_1)).to eql filter_2_instance
        end

        it 'returns the NotExistingFilter if the key is not matched' do
          expect(includer.filter_for(:f_i1)).to be_a Queries::NotExistingFilter
        end

        it 'returns the NotExistingFilter if the key is matched but the name is not' do
          expect(includer.filter_for(:f_2)).to be_a Queries::NotExistingFilter
        end
      end

      context 'is false if unavailable' do
        let(:filter_2_available) { false }

        it 'returns the NotExistingFilter' do
          expect(includer.filter_for(:f_i)).to be_a Queries::NotExistingFilter
        end
      end
    end
  end
end
