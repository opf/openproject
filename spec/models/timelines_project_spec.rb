#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe Project do
  describe '- Relations ' do
    describe '#project_type' do
      it 'can read the project_type w/ the help of the belongs_to association' do
        project_type = FactoryGirl.create(:project_type)
        project      = FactoryGirl.create(:project, :project_type_id => project_type.id)

        project.reload

        project.project_type.should == project_type
      end
    end

    describe '#responsible' do
      it 'can read the responsible w/ the help of the belongs_to association' do
        user    = FactoryGirl.create(:user)
        project = FactoryGirl.create(:project, :responsible_id => user.id)

        project.reload

        project.responsible.should == user
      end
    end

    describe '#enabled_planning_element_types' do
      it 'can read enabled_planning_element_types w/ the help of the has_many association' do
        project                       = FactoryGirl.create(:project)
        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :project_id => project.id)

        project.reload

        project.enabled_planning_element_types.size.should == 1
        project.enabled_planning_element_types.first.should == enabled_planning_element_type
      end

      it 'deletes associated enabled_planning_element_types' do
        project                       = FactoryGirl.create(:project)
        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :project_id => project.id)
        project.reload

        project.destroy

        expect { enabled_planning_element_type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#planning_element_types' do
      it 'can read planning_element_types w/ the help of the has_many-through association' do
        planning_element_type = FactoryGirl.create(:planning_element_type)
        project               = FactoryGirl.create(:project)

        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :project_id => project.id,
                                                       :planning_element_type_id => planning_element_type.id)

        project.reload

        project.planning_element_types.size.should == 1
        project.planning_element_types.first.should == planning_element_type
      end
    end

    describe '#timelines' do
      it 'can read timelines w/ the help of the has_many association' do
        project  = FactoryGirl.create(:project)
        timeline = FactoryGirl.create(:timeline, :project_id => project.id)

        project.reload

        project.timelines.size.should  == 1
        project.timelines.first.should == timeline
      end

      it 'deletes associated timelines' do
        project  = FactoryGirl.create(:project)
        timeline = FactoryGirl.create(:timeline, :project_id => project.id)

        project.reload

        project.destroy

        expect { timeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#planning_elements' do
      it 'can read planning elements w/ the help of the has_many association' do
        project          = FactoryGirl.create(:project)
        planning_element = FactoryGirl.create(:planning_element, :project_id => project.id)

        project.reload

        project.planning_elements.size.should  == 1
        project.planning_elements.first.should == planning_element
      end

      it 'deletes associated planning elements' do
        planning_element = FactoryGirl.create(:planning_element)

        planning_element.project.destroy

        expect { planning_element.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated planning elements so that alternate dates may also be deleted'
    end

    describe '#reportings' do
      it 'can read reportings via source w/ the help of the has_many association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting, :project_id => project.id)

        project.reload

        project.reportings.size.should  == 1
        project.reportings.first.should == reporting
      end

      it 'can read reportings via target w/ the help of the has_many association' do
        project   = FactoryGirl.create(:project)
        reporting = FactoryGirl.create(:reporting, :reporting_to_project_id => project.id)

        project.reload

        project.reportings.size.should  == 1
        project.reportings.first.should == reporting
      end

      it 'deletes associated reportings' do
        project     = FactoryGirl.create(:project)
        reporting_a = FactoryGirl.create(:reporting, :project_id => project.id)
        reporting_b = FactoryGirl.create(:reporting, :reporting_to_project_id => project.id)

        project.reload

        project.destroy

        expect { reporting_a.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { reporting_b.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'exposes the via source helper associations' do
        project = FactoryGirl.create(:project)

        expect { project.reportings_via_source }.to_not raise_error(NoMethodError)
      end

      it 'exposes the via target helper associations' do
        project = FactoryGirl.create(:project)

        expect { project.reportings_via_target }.to_not raise_error(NoMethodError)
      end
    end

    describe '#scenarios' do
      it 'can read reportings w/ the help of the has_many association' do
        project  = FactoryGirl.create(:project)
        scenario = FactoryGirl.create(:scenario, :project_id => project.id)

        project.reload

        project.scenarios.size.should  == 1
        project.scenarios.first.should == scenario
      end

      it 'deletes associated scenarios' do
        project  = FactoryGirl.create(:project)
        scenario = FactoryGirl.create(:scenario, :project_id => project.id)

        project.reload

        project.destroy

        expect { scenario.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated scenarios so that alternate dates may also be deleted'
    end

    describe ' - project associations ' do
      describe '#project_associations' do
        # has_many
        it 'can read project_associations where project is project_a' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          association = FactoryGirl.create(:project_association,
                                       :project_a_id => project.id,
                                       :project_b_id => other_project.id)

          project.reload

          project.project_associations.size.should  == 1
          project.project_associations.first.should == association
        end

        it 'can read project_associations where project is project_b' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          association = FactoryGirl.create(:project_association,
                                       :project_b_id => other_project.id,
                                       :project_a_id => project.id)

          project.reload

          project.project_associations.size.should  == 1
          project.project_associations.first.should == association
        end

        it 'deletes project_associations' do
          project_a = FactoryGirl.create(:project)
          project_b = FactoryGirl.create(:project)
          project_x = FactoryGirl.create(:project)

          association_a = FactoryGirl.create(:project_association,
                                         :project_a_id => project_a.id,
                                         :project_b_id => project_x.id)
          association_b = FactoryGirl.create(:project_association,
                                         :project_a_id => project_x.id,
                                         :project_b_id => project_b.id)

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

           FactoryGirl.create(:project_association, :project_a_id => project.id,
                                                          :project_b_id => other_project.id)

          project.reload

          project.associated_projects.size.should  == 1
          project.associated_projects.first.should == other_project
        end

        it 'can read associated_projects where project is project_b' do
          project = FactoryGirl.create(:project)
          other_project = FactoryGirl.create(:project)

          FactoryGirl.create(:project_association, :project_b_id => other_project.id,
                                                         :project_a_id => project.id)

          project.reload

          project.associated_projects.size.should  == 1
          project.associated_projects.first.should == other_project
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
        it 'gets all default planning element types assigned as enabled planning element types' do
          planning_element_type_a = FactoryGirl.create(:planning_element_type)
          planning_element_type_b = FactoryGirl.create(:planning_element_type)
          planning_element_type_c = FactoryGirl.create(:planning_element_type)
          planning_element_type_x = FactoryGirl.create(:planning_element_type)

          pe_types = [planning_element_type_a, planning_element_type_b, planning_element_type_c]

          project_type = FactoryGirl.create(:project_type)

          pe_types.each do |type|
            FactoryGirl.create(:default_planning_element_type,
                           :project_type_id          => project_type.id,
                           :planning_element_type_id => type.id)
          end

          # using build & save instead of create to make sure all callbacks and
          # validations are triggered
          project = FactoryGirl.build(:project, :project_type_id => project_type.id)
          project.save

          project.reload

          project.planning_element_types.size.should == 3
          pe_types.each do |type|
            project.planning_element_types.should be_include(type)
          end
        end

        it 'gets no extra planning element types assigned if there are already some' do
          planning_element_type_a = FactoryGirl.create(:planning_element_type)
          planning_element_type_b = FactoryGirl.create(:planning_element_type)
          planning_element_type_c = FactoryGirl.create(:planning_element_type)
          planning_element_type_x = FactoryGirl.create(:planning_element_type)

          pe_types = [planning_element_type_a, planning_element_type_b, planning_element_type_c]

          project_type = FactoryGirl.create(:project_type)

          pe_types.each do |type|
            FactoryGirl.create(:default_planning_element_type,
                           :project_type_id          => project_type.id,
                           :planning_element_type_id => type.id)
          end


          # using build & save instead of create to make sure all callbacks and
          # validations are triggered
          project = FactoryGirl.build(:project, :project_type_id => project_type.id,
                                            :planning_element_types => [planning_element_type_x])
          project.save

          project.reload

          project.planning_element_types.size.should == 1
          project.planning_element_types.first.should == planning_element_type_x
        end
      end
    end
  end
end
