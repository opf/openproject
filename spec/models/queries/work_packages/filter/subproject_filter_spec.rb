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

describe Queries::WorkPackages::Filter::SubprojectFilter, type: :model do
  it_behaves_like 'basic query filter' do
    let(:type) { :list_optional }
    let(:class_key) { :subproject_id }
    let(:name) { I18n.t('query_fields.subproject_id') }
    let(:project) { FactoryBot.build_stubbed :project }
    let(:relation) { double(ActiveRecord::Relation) }
    let(:projects) { [] }
    let(:plucked) { projects.map { |p| [p.id, p.name] } }

    before do
      if project
        allow(project)
        .to receive_message_chain(:descendants, :visible)
        .and_return relation
      end

      allow(relation)
        .to receive(:pluck)
        .with(:id, :name)
        .and_return plucked
    end

    describe '#available?' do
      context 'with a project and that project not being a leaf
               and the project having visible descendants' do
        let(:subproject) { FactoryBot.build_stubbed(:project) }
        let(:projects) { [subproject] }

        before do
          allow(relation).to receive(:any?)
          .and_return true

          allow(project)
            .to receive(:leaf?)
            .and_return false
        end

        it 'is available' do
          expect(instance).to be_available
        end
      end

      context 'without a project' do
        let(:project) { nil }

        it 'is unavailable' do
          expect(instance).to_not be_available
        end
      end

      context 'with a project and that project is a leaf' do
        before do
          allow(project)
            .to receive(:leaf?)
            .and_return true
        end

        it 'is unavailable' do
          expect(instance).to_not be_available
        end
      end

      context 'with a project and that project not being a leaf
               but the user not seeing any of the descendants' do
        before do
          allow(project)
            .to receive(:leaf?)
            .and_return false

          allow(relation).to receive(:any?)
            .and_return false
        end

        it 'is unavailable' do
          expect(instance).to_not be_available
        end
      end
    end

    describe '#allowed_values' do
      let(:subproject1) { FactoryBot.build_stubbed(:project) }
      let(:subproject2) { FactoryBot.build_stubbed(:project) }
      let(:projects) { [subproject1, subproject2] }

      it 'returns a list of all visible descendants' do
        expect(instance.allowed_values).to match_array [[subproject1.name, subproject1.id.to_s],
                                                        [subproject2.name, subproject2.id.to_s]]
      end
    end

    describe '#ar_object_filter?' do
      it 'is true' do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe '#available_operators' do
      it 'is the same as for every list_optional but the `all` operator comes first' do
        expect(instance.available_operators)
          .to eql([::Queries::Operators::All, ::Queries::Operators::None,
                   ::Queries::Operators::Equals, ::Queries::Operators::NotEquals])
      end
    end

    describe '#where' do
      let(:subproject1) { FactoryBot.build_stubbed(:project) }
      let(:subproject2) { FactoryBot.build_stubbed(:project) }
      let(:projects) { [subproject1, subproject2] }

      context 'for the equals operator' do
        let(:operator) { '=' }
        let(:values) { [subproject1.id.to_s] }

        it 'returns an sql filtering for project id eql self or specified values' do
          expect(instance.where)
            .to eql("projects.id IN (#{project.id},#{subproject1.id})")
        end
      end

      context 'for the not equals operator' do
        let(:operator) { '!' }
        let(:values) { [subproject1.id.to_s] }

        it 'returns an sql filtering for project id eql self and all subprojects excluding specified values' do
          expect(instance.where)
            .to eql("projects.id IN (#{project.id},#{subproject2.id})")
        end
      end

      context 'for the all operator' do
        let(:operator) { '*' }
        let(:values) { [] }

        it 'returns an sql filtering for project id eql self and all subprojects' do
          expect(instance.where)
            .to eql("projects.id IN (#{project.id},#{subproject1.id},#{subproject2.id})")
        end
      end

      context 'for the none operator' do
        let(:operator) { '!*' }
        let(:values) { [] }

        it 'returns an sql filtering for only the project id (and by that excluding all subprojects)' do
          expect(instance.where)
            .to eql("projects.id IN (#{project.id})")
        end
      end
    end
  end
end
