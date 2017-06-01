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

describe ::API::V3::StringObjects::StringObjectRepresenter do
  let(:value) { 'foo bar' }
  let(:representer) { described_class.new(value) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject { representer.to_json }

    it 'should indicate its type' do
      is_expected.to be_json_eql('StringObject'.to_json).at_path('_type')
    end

    describe 'links' do
      it 'should link to self' do
        path = api_v3_paths.string_object(value)

        is_expected.to be_json_eql(path.to_json).at_path('_links/self/href')
      end
    end

    describe 'value' do
      it 'should have a value' do
        is_expected.to be_json_eql(value.to_json).at_path('value')
      end

      context 'value is nil' do
        let(:value) { nil }

        it 'should be the empty string' do
          is_expected.to be_json_eql(''.to_json).at_path('value')
        end
      end
    end
  end
end
