shared_examples_for "a model with non-negative duration" do
  # it is assumed, that planning elements start on start_date 00:01 and end
  # on end_date 23:59. Therefore, if start_date and end_date are on the very
  # same day, the duration should be 1.
  describe 'duration' do
    describe 'when start date == end date' do
      it 'is 1' do
        subject.start_date = Date.today
        subject.end_date   = Date.today
        subject.duration.should == 1
      end
    end

    describe 'when end date > start date' do
      it 'is the difference between end date and start date plus one day' do
        subject.start_date = 5.days.ago.to_date
        subject.end_date   = Date.today
        subject.duration.should == 6
      end
    end

    describe 'when start date > end date' do
      it 'is 1' do
        subject.start_date = Date.today
        subject.end_date   = 5.days.ago.to_date
        subject.duration.should == 1
      end
    end
  end
end
