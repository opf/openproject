#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  let(:representer)  { described_class.new(model) }
  let(:model)        { ::API::V3::WorkPackages::WorkPackageModel.new(
      work_package: work_package
    )
  }
  let(:work_package) { FactoryGirl.build(:work_package,
      created_at: DateTime.now,
      updated_at: DateTime.now
    )
  }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { should have_json_path('id') }

      it { should have_json_path('description') }
      it { should have_json_path('rawDescription') }

      it { should have_json_path('dueDate') }

      it { should have_json_path('percentageDone') }
      it { should have_json_path('priority') }

      it { should have_json_path('projectId') }
      it { should have_json_path('projectName') }

      it { should have_json_path('startDate') }
      it { should have_json_path('status') }
      it { should have_json_path('subject') }
      it { should have_json_path('type') }

      it { should have_json_path('versionId') }
      it { should have_json_path('versionName') }

      it { should have_json_path('createdAt') }
      it { should have_json_path('updatedAt') }
    end

    describe 'estimatedTime' do
      it { should have_json_type(Object).at_path('estimatedTime') }

      it { should have_json_path('estimatedTime/units') }
      it { should have_json_path('estimatedTime/value') }
    end

    describe '_links' do
      it { should have_json_type(Object).at_path('_links') }

      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
        expect(subject).to have_json_path('_links/self/title')
      end
    end

    describe '_embedded' do
      it { should have_json_type(Object).at_path('_embedded') }

      describe 'activities' do
        it { should have_json_type(Array).at_path('_embedded/activities') }
        it { should have_json_size(0).at_path('_embedded/activities') }
      end

      describe 'relations' do
        it { should have_json_type(Array).at_path('_embedded/relations') }

        context 'with no relations' do
          before do
            expect(work_package).to receive(:relations) {
              []
            }
          end

          it { should have_json_size(0).at_path('_embedded/relations') }
        end

        context 'with relations' do
          before do
            expect(work_package).to receive(:relations) {
              FactoryGirl.build_list(:relation, 3)
            }
          end

          it { should have_json_size(3).at_path('_embedded/relations') }
          it { should have_json_path('_embedded/relations/2/_type') }
          it { should have_json_path('_embedded/relations/2/_links/workPackage/href') }
        end
      end
    end
  end
end
