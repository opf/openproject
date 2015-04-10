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

require File.expand_path('../../spec_helper', __FILE__)

describe ProjectType, type: :model do
  describe '- Relations ' do
    describe '#projects' do
      it 'can read projects w/ the help of the has_many association' do
        project_type = FactoryGirl.create(:project_type)
        project      = FactoryGirl.create(:project, project_type_id: project_type.id)

        project_type.reload

        expect(project_type.projects.size).to eq(1)
        expect(project_type.projects.first).to eq(project)
      end
    end

    describe '#available_project_statuses' do
      it 'can read available_project_statuses w/ the help of the has_many association' do
        project_type             = FactoryGirl.create(:project_type)
        reported_project_status  = FactoryGirl.create(:reported_project_status)
        available_project_status =
          FactoryGirl.create(:available_project_status,
                             reported_project_status_id: reported_project_status.id,
                             project_type_id:            project_type.id)

        project_type.reload

        expect(project_type.available_project_statuses.size).to eq(1)
        expect(project_type.available_project_statuses.first).to eq(available_project_status)
      end
    end

    describe '#reported_project_statuses' do
      it 'can read reported_project_statuses w/ the help of the has_many :through association' do
        project_type            = FactoryGirl.create(:project_type)
        reported_project_status = FactoryGirl.create(:reported_project_status)
        available_project_status =
          FactoryGirl.create(:available_project_status,
                             reported_project_status_id: reported_project_status.id,
                             project_type_id:            project_type.id)

        project_type.reload

        expect(project_type.reported_project_statuses.size).to eq(1)
        expect(project_type.reported_project_statuses.first).to eq(reported_project_status)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { name:               'Project Type No. 1',
        allows_association: true }
    }

    describe 'name' do
      it 'is invalid w/o a name' do
        attributes[:name] = nil
        project_type = ProjectType.new(attributes)

        expect(project_type).not_to be_valid

        expect(project_type.errors[:name]).to be_present
        expect(project_type.errors[:name]).to eq(["can't be blank"])
      end

      it 'is invalid w/ a name longer than 255 characters' do
        attributes[:name] = 'A' * 500
        project_type = ProjectType.new(attributes)

        expect(project_type).not_to be_valid

        expect(project_type.errors[:name]).to be_present
        expect(project_type.errors[:name]).to eq(['is too long (maximum is 255 characters)'])
      end
    end

    describe 'allows_association' do
      it 'is invalid w/o the allows_association property' do
        attributes[:allows_association] = nil
        project_type = ProjectType.new(attributes)

        expect(project_type).not_to be_valid

        expect(project_type.errors[:allows_association]).to be_present
      end

      it 'is valid w/ allows_association set to true' do
        attributes[:allows_association] = true
        project_type = ProjectType.new(attributes)

        expect(project_type).to be_valid
      end

      it 'is valid w/ allows_association set to false' do
        attributes[:allows_association] = false
        project_type = ProjectType.new(attributes)

        expect(project_type).to be_valid
      end
    end
  end
end
