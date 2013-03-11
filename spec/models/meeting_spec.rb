require 'spec_helper'

describe Meeting do
  it {should belong_to :project}
  it {should belong_to :author}
  it {should validate_presence_of :title}
  it {should validate_presence_of :start_time}
  it {pending; should accept_nested_attributes_for :participants} # geht das?

  before(:all) do
    @m = Factory.build :meeting, :title => "dingens"
  end

  describe "to_s" do
    it {@m.to_s.should == "dingens"}
  end

  describe "start_date" do
    it {@m.start_date.should == Date.tomorrow}
  end

  describe "start_month" do
    it {@m.start_month.should == Date.tomorrow.month}
  end

  describe "start_year" do
    it {@m.start_year.should == Date.tomorrow.year}
  end

  describe "end_time" do
    it {@m.end_time.should == Date.tomorrow + 11.hours}
  end

  describe "time-sorted finder" do
    it {pending}
  end

  describe "Journalized Objects" do
    before(:each) do
      @project ||= Factory.create(:project_with_trackers)
      @current = Factory.create(:user, :login => "user1", :mail => "user1@users.com")
      User.stub!(:current).and_return(@current)
    end

    it 'should work with meeting' do
      @meeting ||= Factory.create(:meeting, :title => "Test", :project => @project, :author => @current)

      initial_journal = @meeting.journals.first
      recreated_journal = @meeting.recreate_initial_journal!
      initial_journal.identical?(recreated_journal).should be true
    end
  end
end
