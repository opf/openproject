#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::AvailableFilterOptions, type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:register) { Queries::WorkPackages::FilterRegister }

  class HelperClass
    attr_accessor :project

    def initialize(project)
      self.project = project
    end

    include Queries::WorkPackages::AvailableFilterOptions

    def filter_register
      register_class
    end
  end

  let(:includer) {
    includer = HelperClass.new(project)

    allow(includer)
      .to receive(:filter_register)
      .and_return(register)

    includer
  }

  describe '#work_package_filter_available?' do
    let(:filter_1_available) { true }
    let(:filter_2_available) { true }
    let(:registered_filters) { [filter_1, filter_2] }

    let(:filter_1) do
      instance = double('filter_1_instance')

      allow(instance)
        .to receive(:available?)
        .and_return(filter_1_available)

      filter = double('filter_1')

      allow(filter)
        .to receive(:key)
        .and_return(:filter_1)

      allow(filter)
        .to receive(:create)
        .and_return(filter.key => instance)

      filter
    end

    let(:filter_2) do
      instance = double('filter_2_instance')

      allow(instance)
        .to receive(:available?)
        .and_return(filter_2_available)

      filter = double('filter_2')

      allow(filter)
        .to receive(:key)
        .and_return(/f_\d+/)

      allow(filter)
        .to receive(:create)
        .and_return('f_1' => instance)

      filter
    end

    let(:register) do
      register = double('register')
      allow(register)
        .to receive(:filters)
        .and_return(registered_filters)

      register
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
          .to receive(:create)
          .and_return(filter.key => instance)

        filter
      end

      context 'if available' do
        let(:filter_3_available) { false }

        it 'is true' do
          expect(includer.work_package_filter_available?(:filter_1)).to be_truthy
        end

        it 'is false if the key is not matched' do
          expect(includer.work_package_filter_available?(:not_a_filter_name)).to be_falsey
        end
      end

      context 'if not available' do
        let(:filter_1_available) { false }
        let(:filter_3_available) { true }

        it 'is false' do
          expect(includer.work_package_filter_available?(:filter_1)).to be_falsey
        end
      end
    end

    context 'for a filter identified by a regexp' do
      context 'is true if if available' do
        it 'is true' do
          expect(includer.work_package_filter_available?(:f_1)).to be_truthy
        end

        it 'is false if the key is not matched' do
          expect(includer.work_package_filter_available?(:f_i1)).to be_falsey
        end

        it 'is false if the regexp matches but the created instance key does not' do
          expect(includer.work_package_filter_available?(:f_2)).to be_falsey
        end
      end

      context 'is false if if unavailable' do
        let(:filter_2_available) { false }

        it 'is false' do
          expect(includer.work_package_filter_available?(:f_1)).to be_falsey
        end
      end
    end
  end
end
