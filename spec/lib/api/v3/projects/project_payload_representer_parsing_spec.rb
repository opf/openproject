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

describe ::API::V3::Projects::ProjectPayloadRepresenter, 'parsing' do
  include ::API::V3::Utilities::PathHelper

  let(:object) do
    OpenStruct.new available_custom_fields: []
  end
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.create(object, current_user: user)
  end

  describe 'properties' do
    context 'status' do
      let(:hash) do
        {
          'status' => 'on track',
          'statusExplanation' => { 'raw' => 'status code explanation' }
        }
      end

      it 'updates code' do
        project = representer.from_hash(hash)
        expect(project.status[:code])
          .to eql(:on_track)

        expect(project.status[:explanation])
          .to eql('status code explanation')
      end

      context 'with code not provided' do
        let(:hash) do
          {
            'statusExplanation' => { 'raw' => 'status code explanation' }
          }
        end

        it 'does not set code' do
          project = representer.from_hash(hash)
          expect(project.status[:code])
            .to be_nil
        end

        it 'updates explanation' do
          project = representer.from_hash(hash)
          expect(project.status[:explanation])
            .to eql('status code explanation')
        end
      end

      context 'with explanation not provided' do
        let(:hash) do
          {
            'status' => 'off track'
          }
        end

        it 'does set code' do
          project = representer.from_hash(hash)
          expect(project.status[:code])
            .to eql :off_track
        end

        it 'does not set explanation' do
          project = representer.from_hash(hash)
          expect(project.status[:explanation])
            .to be_nil
        end
      end

      context 'with null for a scope' do
        let(:hash) do
          {
            'status' => nil
          }
        end

        it 'does set status to nil' do
          project = representer.from_hash(hash).to_h

          expect(project)
            .to have_key(:status)

          status = project[:status]
          expect(status)
            .to have_key(:code)

          expect(status)
            .not_to have_key(:explanation)

          expect(status[:code])
            .to eq nil
        end
      end
    end
  end
end
