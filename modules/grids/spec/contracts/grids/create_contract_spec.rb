#-- encoding: UTF-8

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
require_relative './shared_examples'

describe Grids::CreateContract do
  include_context 'grid contract'
  include_context 'model contract'

  it_behaves_like 'shared grid contract attributes'

  describe 'type' do
    it_behaves_like 'is writable' do
      let(:attribute) { :type }
      let(:value) { 'Grids::MyPage' }
    end
  end

  describe 'user_id' do
    let(:grid) { FactoryBot.build_stubbed(:grid, default_values) }

    it_behaves_like 'is not writable' do
      let(:attribute) { :user_id }
      let(:value) { 5 }
    end

    context 'for a Grids::MyPage' do
      let(:grid) { FactoryBot.build_stubbed(:my_page, default_values) }

      it_behaves_like 'is writable' do
        let(:attribute) { :user_id }
        let(:value) { 5 }
      end
    end
  end

  describe 'project_id' do
    let(:grid) { FactoryBot.build_stubbed(:grid, default_values) }

    it_behaves_like 'is not writable' do
      let(:attribute) { :project_id }
      let(:value) { 5 }
    end

    context 'for a Grids::MyPage' do
      let(:grid) { FactoryBot.build_stubbed(:my_page, default_values) }

      it_behaves_like 'is not writable' do
        let(:attribute) { :project_id }
        let(:value) { 5 }
      end
    end
  end

  describe '#assignable_values' do
    context 'for scope' do
      it 'calls the grid configuration for the available values' do
        scopes = double('scopes')

        allow(Grids::Configuration)
          .to receive(:all_scopes)
          .and_return(scopes)

        expect(instance.assignable_values(:scope, user))
          .to eql scopes
      end
    end

    context 'for something else' do
      it 'returns nil' do
        expect(instance.assignable_values(:something, user))
          .to be_nil
      end
    end
  end
end
