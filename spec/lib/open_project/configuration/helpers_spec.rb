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
require 'open_project/configuration/helpers'

describe OpenProject::Configuration::Helpers do
  let(:config) {
    {}.tap do |config|
      config.extend OpenProject::Configuration::Helpers
    end
  }

  describe '#array' do
    def array(value)
      config.send :array, value
    end

    context 'with single string value' do
      it 'returns an array containing the value' do
        arr = array 'test'

        expect(arr).to eq ['test']
      end
    end

    context 'with an array' do
      it 'returns the array' do
        arr = ['arrgh']

        expect(array(arr)).to eq arr
      end
    end

    context 'with a space separated string' do
      it 'returns an array of the values' do
        value = 'one two three'

        expect(array(value)).to eq ['one', 'two', 'three']
      end
    end
  end

  describe '#hidden_menu_items' do
    before do
      items = config['hidden_menu_items'] = {}
      items['admin_menu'] = 'users colors'
      items['project_menu'] = 'info'
      items['top_menu'] = []
    end

    it 'works with arrays' do
      expect(config.hidden_menu_items['top_menu']).to eq []
    end

    it 'works with single string values' do
      expect(config.hidden_menu_items['project_menu']).to eq ['info']
    end

    it 'work with space separated string values' do
      expect(config.hidden_menu_items['admin_menu']).to eq ['users', 'colors']
    end
  end
end
