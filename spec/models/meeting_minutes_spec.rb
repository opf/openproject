require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "MeetingMinutes" do
  before(:all) do
    @min = Factory.build :meeting_minutes
  end

  # meeting minutes are editable when the meeting agenda is locked
  describe "#editable?" do
    before(:each) do
      @mee = Factory.build :meeting
      @min.meeting = @mee
    end
    describe "with no agenda present" do
      it "is not editable" do
        @min.editable?.should be_false
      end
    end
    describe "with an agenda present" do
      before(:each) do
        @a = Factory.build :meeting_agenda
        @mee.agenda = @a
      end
      it "is not editable when the agenda is open" do
        @min.editable?.should be_false
      end
      it "is editable when the agenda is closed" do
        @a.lock!
        @min.editable?.should be_true
      end
    end
  end
end