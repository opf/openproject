require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  describe 'backlogs_preference' do
    describe 'task_color' do
      it 'reads from and writes to a user preference' do
        u = Factory.create(:user)
        u.backlogs_preference(:task_color, '#FFCC33')

        u.backlogs_preference(:task_color).should == '#FFCC33'
        u.reload
        u.backlogs_preference(:task_color).should == '#FFCC33'
      end

      it 'computes a random color and persists it, when none is set' do
        u = Factory.build(:user)

        generated_task_color = u.backlogs_preference(:task_color)
        generated_task_color.should =~ /^#[0-9A-F]{6}$/

        u.backlogs_preference(:task_color).should == generated_task_color
        u.should be_new_record
        u.save

        u.reload
        u.backlogs_preference(:task_color).should == generated_task_color
      end
    end
  end
end
