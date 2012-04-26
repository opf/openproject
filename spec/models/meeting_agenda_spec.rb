require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "MeetingAgenda" do
  before(:all) do
    #@m = Factory.build :meeting, :title => "dingens"
    @a = Factory.build :meeting_agenda, :text => "Some content...\n\nMore content!\n\nExtraordinary content!!"
  end
  
  # TODO: Test the right user and messages are set in the history
  describe "#lock!" do
    it "locks the agenda" do
      @a.save
      @a.reload
      @a.lock!
      @a.reload
      @a.locked.should be_true
    end
  end
  
  describe "#unlock!" do
    it "unlocks the agenda" do
      @a.locked = true
      @a.save
      @a.reload
      @a.unlock!
      @a.reload
      @a.locked.should be_false
    end
  end
  
  # a meeting agenda is editable when it is not locked
  describe "#editable?" do
    it "is editable when not locked" do
      @a.editable?.should be_true
    end
    it "is not editable when locked" do
      @a.locked = true
      @a.editable?.should be_false
    end
  end
end
