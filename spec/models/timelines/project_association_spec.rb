require File.expand_path('../../../spec_helper', __FILE__)

describe Timelines::ProjectAssociation do
  describe '- Relations ' do
    describe '#project_a' do
      it 'can read the first project w/ the help of the belongs_to association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:timelines_project_association,
                                     :project_a_id => project_a.id,
                                     :project_b_id => project_b.id)

        association.project_a.should == project_a
      end

      it 'can read the second project w/ the help of the belongs_to association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:timelines_project_association,
                                     :project_a_id => project_a.id,
                                     :project_b_id => project_b.id)

        association.project_b.should == project_b
      end

      it 'can read both projects w/ the help of the pseudo has_many association' do
        project_a = FactoryGirl.create(:project)
        project_b = FactoryGirl.create(:project)

        association = FactoryGirl.create(:timelines_project_association,
                                     :project_a_id => project_a.id,
                                     :project_b_id => project_b.id)

        association.projects.should include(project_a)
        association.projects.should include(project_b)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      {:project_a_id => 1,
       :project_b_id => 2}
    }

    before {
      FactoryGirl.create(:project, :id => 1)
      FactoryGirl.create(:project, :id => 2)
    }

    it { Timelines::ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, :without_protection => true) }.should be_valid }

    describe 'project_a' do
      it 'is invalid w/o a project_a' do
        attributes[:project_a_id] = nil
        project_association = Timelines::ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, :without_protection => true) }

        project_association.should_not be_valid

        project_association.errors[:project_a].should be_present
        project_association.errors[:project_a].should == ["can't be blank"]
      end
    end

    describe 'project_b' do
      it 'is invalid w/o a project_b' do
        attributes[:project_b_id] = nil
        project_association = Timelines::ProjectAssociation.new.tap { |a| a.send(:assign_attributes, attributes, :without_protection => true) }

        project_association.should_not be_valid

        project_association.errors[:project_b].should be_present
        project_association.errors[:project_b].should == ["can't be blank"]
      end
    end
  end
end
