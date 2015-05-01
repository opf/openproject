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

describe ProjectAssociation, type: :model do
  describe '- Relations ' do
    describe '#project_a' do
      it 'can read the first project w/ the help of the belongs_to association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:project_association,
                                         project_a_id: project_a.id,
                                         project_b_id: project_b.id)

        expect(association.project_a).to eq(project_a)
      end

      it 'can read the second project w/ the help of the belongs_to association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:project_association,
                                         project_a_id: project_a.id,
                                         project_b_id: project_b.id)

        expect(association.project_b).to eq(project_b)
      end

      it 'can read both projects w/ the help of the pseudo has_many association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:project_association,
                                         project_a_id: project_a.id,
                                         project_b_id: project_b.id)

        expect(association.projects).to include(project_a)
        expect(association.projects).to include(project_b)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { project_a_id: 1,
        project_b_id: 2 }
    }

    before {
      FactoryGirl.create(:project, id: 1)
      FactoryGirl.create(:project, id: 2)
    }

    it { expect(ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, without_protection: true) }).to be_valid }

    it 'should be invalid for a self referential association' do
      attributes[:project_b_id] = attributes[:project_a_id]

      project_association = ProjectAssociation.new do |a|
        a.send(:assign_attributes, attributes, without_protection: true)
      end

      expect(project_association).not_to be_valid

      expect(project_association.errors[:base]).to eq([I18n.t(:identical_projects, scope: [:activerecord,
                                                                                           :errors,
                                                                                           :models,
                                                                                           :project_association])])
    end

    describe 'project_a' do
      it 'is invalid w/o a project_a' do
        attributes[:project_a_id] = nil
        project_association = ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, without_protection: true) }

        expect(project_association).not_to be_valid

        expect(project_association.errors[:project_a]).to eq(["can't be blank"])
      end
    end

    describe 'project_b' do
      it 'is invalid w/o a project_b' do
        attributes[:project_b_id] = nil
        project_association = ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, without_protection: true) }

        expect(project_association).not_to be_valid

        expect(project_association.errors[:project_b]).to eq(["can't be blank"])
      end
    end
  end
end
