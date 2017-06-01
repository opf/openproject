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

describe Project, type: :model do
  describe '- Relations ' do
    describe '#project_type' do
      it 'can read the project_type w/ the help of the belongs_to association' do
        project_type = FactoryGirl.create(:project_type)
        project      = FactoryGirl.create(:project, project_type_id: project_type.id)

        project.reload

        expect(project.project_type).to eq(project_type)
      end
    end

    describe '#responsible' do
      it 'can read the responsible w/ the help of the belongs_to association' do
        user    = FactoryGirl.create(:user)
        project = FactoryGirl.create(:project, responsible_id: user.id)

        project.reload

        expect(project.responsible).to eq(user)
      end
    end

    describe '#types' do
      it 'can read types w/ the help of the has_many association' do
        project = FactoryGirl.create(:project)
        type    = FactoryGirl.create(:type)

        project.types = [type]
        project.save

        project.reload

        expect(project.types.size).to eq(1)
        expect(project.types.first).to eq(type)
      end

      it 'can read types w/ the help of the has_many-through association' do
        project               = FactoryGirl.create(:project)
        type                  = FactoryGirl.create(:type)

        project.types = [type]
        project.save

        project.reload

        expect(project.types.size).to eq(1)
        expect(project.types.first).to eq(type)
      end
    end

    describe '#timelines' do
      it 'can read timelines w/ the help of the has_many association' do
        project  = FactoryGirl.create(:project)
        timeline = FactoryGirl.create(:timeline, project_id: project.id)

        project.reload

        expect(project.timelines.size).to eq(1)
        expect(project.timelines.first).to eq(timeline)
      end

      it 'deletes associated timelines' do
        project  = FactoryGirl.create(:project)
        timeline = FactoryGirl.create(:timeline, project_id: project.id)

        project.reload

        project.destroy

        expect { timeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#reportings' do
      it 'can read reportings via source w/ the help of the has_many association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting, project_id: project.id)

        project.reload

        expect(project.reportings.size).to eq(1)
        expect(project.reportings.first).to eq(reporting)
      end

      it 'can read reportings via target w/ the help of the has_many association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting, reporting_to_project_id: project.id)

        project.reload

        expect(project.reportings.size).to eq(1)
        expect(project.reportings.first).to eq(reporting)
      end

      it 'deletes associated reportings' do
        project     = FactoryGirl.create(:project)
        reporting_a = FactoryGirl.create(:reporting, project_id: project.id)
        reporting_b = FactoryGirl.create(:reporting, reporting_to_project_id: project.id)

        project.reload

        project.destroy

        expect { reporting_a.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { reporting_b.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'exposes the via source helper associations' do
        project = FactoryGirl.create(:project)

        expect { project.reportings_via_source }.not_to raise_error
      end

      it 'exposes the via target helper associations' do
        project = FactoryGirl.create(:project)

        expect { project.reportings_via_target }.not_to raise_error
      end
    end

    describe ' - project associations ' do
      describe '#project_associations' do
        # has_many
        it 'can read project_associations where project is project_a' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          association = FactoryGirl.create(:project_association,
                                           project_a_id: project.id,
                                           project_b_id: other_project.id)

          project.reload

          expect(project.project_associations.size).to eq(1)
          expect(project.project_associations.first).to eq(association)
        end

        it 'can read project_associations where project is project_b' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          association = FactoryGirl.create(:project_association,
                                           project_b_id: other_project.id,
                                           project_a_id: project.id)

          project.reload

          expect(project.project_associations.size).to eq(1)
          expect(project.project_associations.first).to eq(association)
        end

        it 'deletes project_associations' do
          project_a = FactoryGirl.create(:project)
          project_b = FactoryGirl.create(:project)
          project_x = FactoryGirl.create(:project)

          association_a = FactoryGirl.create(:project_association,
                                             project_a_id: project_a.id,
                                             project_b_id: project_x.id)
          association_b = FactoryGirl.create(:project_association,
                                             project_a_id: project_x.id,
                                             project_b_id: project_b.id)

          project_x.reload
          project_x.destroy

          expect { association_a.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { association_b.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe '#associated_projects' do
        # has_many :through
        it 'can read associated_projects where project is project_a' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          FactoryGirl.create(:project_association, project_a_id: project.id,
                                                   project_b_id: other_project.id)

          project.reload

          expect(project.associated_projects.size).to eq(1)
          expect(project.associated_projects.first).to eq(other_project)
        end

        it 'can read associated_projects where project is project_b' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          FactoryGirl.create(:project_association, project_b_id: other_project.id,
                                                   project_a_id: project.id)

          project.reload

          expect(project.associated_projects.size).to eq(1)
          expect(project.associated_projects.first).to eq(other_project)
        end

        it 'hides the helper associations' do
          project = FactoryGirl.create(:project)

          expect { project.project_a_associations }.to raise_error(NoMethodError)
          expect { project.project_b_associations }.to raise_error(NoMethodError)
          expect { project.associated_a_projects  }.to raise_error(NoMethodError)
          expect { project.associated_b_projects  }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe '- Creation' do
    describe 'enabled planning elements' do
      describe 'when a new project w/ a project type is created' do
        it 'gets all default types' do
          type_a = FactoryGirl.create(:type, is_default: true)
          type_b = FactoryGirl.create(:type, is_default: true)
          type_c = FactoryGirl.create(:type, is_default: true)
          type_x = FactoryGirl.create(:type)

          types = [type_a, type_b, type_c]

          project = FactoryGirl.create(:project)
          project.save

          project.reload

          expect(project.types.size).to eq(4) # including standard type
          types.each do |type|
            expect(project.types).to be_include(type)
          end
        end

        it 'gets no extra types assigned if there are already some' do
          type_a = FactoryGirl.create(:type)
          type_b = FactoryGirl.create(:type)
          type_c = FactoryGirl.create(:type)
          type_x = FactoryGirl.create(:type)

          types = [type_a, type_b, type_c]

          project_type = FactoryGirl.create(:project_type)

          # using build & save instead of create to make sure all callbacks and
          # validations are triggered
          project = FactoryGirl.build(:project, types: [type_x])
          project.save

          project.reload

          expect(project.types.size).to eq(1)
          expect(project.types.first).to eq(type_x)
        end
      end
    end
  end
end
