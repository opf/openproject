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

describe ::API::V3::CustomOptions::CustomOptionRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:custom_option) { FactoryBot.build_stubbed(:custom_option, custom_field: custom_field) }
  let(:custom_field) { FactoryBot.build_stubbed(:list_wp_custom_field) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.new(custom_option, current_user: user)
  end

  subject { representer.to_json }

  describe 'generation' do
    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.custom_option custom_option.id }
        let(:title) { custom_option.to_s }
      end
    end

    it 'has the type "CustomOption"' do
      is_expected.to be_json_eql('CustomOption'.to_json).at_path('_type')
    end

    it 'has an id' do
      is_expected.to be_json_eql(custom_option.id.to_json).at_path('id')
    end

    it 'has a value' do
      is_expected.to be_json_eql(custom_option.to_s.to_json).at_path('value')
    end
  end
end
