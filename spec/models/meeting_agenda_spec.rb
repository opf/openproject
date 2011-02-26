require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "MeetingAgenda" do
  before(:all) do
    #@m = Factory.build :meeting, :title => "dingens"
    @a = Factory.build :meeting_agenda, :text => "Some content...\n\nMore content!\n\nExtraordinary content!!"
  end
  
  describe "#lock!" do
    it "locks the agenda" do
      @a.save
      @a.lock!
      @a.reload
      @a.locked.should be_true
    end
  end
end