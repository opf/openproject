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

describe ::API::V3::WorkPackages::Schema::WorkPackageSumsSchemaRepresenter do
  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end

  let(:schema) { ::API::V3::WorkPackages::Schema::WorkPackageSumsSchema.new }

  let(:representer) { described_class.create(schema, current_user: current_user) }
  subject { representer.to_json }

  describe 'storyPoints' do
    let(:setting) { ['story_points'] }

    before do
      allow(Setting)
        .to receive(:work_package_list_summable_columns)
        .and_return(setting)
    end

    it_behaves_like 'has basic schema properties' do
      let(:path) { 'storyPoints' }
      let(:type) { 'Integer' }
      let(:name) { I18n.t('activerecord.attributes.work_package.story_points') }
      let(:required) { false }
      let(:writable) { false }
    end

    context 'not marked as summable' do
      let(:setting) { [] }

      it 'does not show story points' do
        is_expected.to_not have_json_path('storyPoints')
      end
    end
  end

  describe 'remainingTime' do
    let(:setting) { ['remaining_time'] }

    shared_examples_for 'has schema for remainingTime' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { 'remainingTime' }
        let(:type) { 'Duration' }
        let(:name) { I18n.t('activerecord.attributes.work_package.remaining_hours') }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    context 'not marked as summable' do
      let(:setting) { [] }

      it 'does not show remaining time' do
        is_expected.to_not have_json_path('remaining time')
      end
    end
  end
end
