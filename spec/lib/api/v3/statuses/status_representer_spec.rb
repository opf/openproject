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

describe ::API::V3::Statuses::StatusRepresenter do
  let(:status) { FactoryGirl.build(:status, id: 42) }
  let(:representer) { described_class.new(status, current_user: double('current_user')) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('Status'.to_json).at_path('_type') }

    describe 'status' do
      it { is_expected.to have_json_path('id') }
      it { is_expected.to have_json_path('name') }
      it { is_expected.to have_json_path('isClosed') }
      it { is_expected.to have_json_path('isDefault') }
      it { is_expected.to have_json_path('position') }
      it { is_expected.to have_json_path('defaultDoneRatio') }

      describe 'values' do
        it { is_expected.to be_json_eql(status.id.to_json).at_path('id') }
        it { is_expected.to be_json_eql(status.name.to_json).at_path('name') }
        it { is_expected.to be_json_eql(status.is_closed.to_json).at_path('isClosed') }
        it { is_expected.to be_json_eql(status.is_default.to_json).at_path('isDefault') }
        it { is_expected.to be_json_eql(status.position.to_json).at_path('position') }
        it {
          is_expected.to be_json_eql(status.default_done_ratio.to_json).at_path('defaultDoneRatio')
        }
      end
    end

    describe '_links' do
      it { is_expected.to have_json_type(Object).at_path('_links') }

      describe 'self' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { "/api/v3/statuses/#{status.id}" }
          let(:title) { status.name }
        end
      end
    end
  end
end
