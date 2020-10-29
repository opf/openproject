RSpec.describe Airbrake::AsyncSender do
  let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }
  let(:queue_size) { 10 }
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: '1',
      workers: 3,
      queue_size: 10,
    )
  end

  describe "#send" do
    context "when sender has the capacity to send" do
      it "sends notices to Airbrake" do
        2.times { subject.send(notice, Airbrake::Promise.new) }
        subject.close

        expect(a_request(:post, endpoint)).to have_been_made.twice
      end

      it "returns a resolved promise" do
        promise = Airbrake::Promise.new
        subject.send(notice, promise)
        subject.close

        expect(promise).to be_resolved
      end
    end

    context "when sender has exceeded the capacity to send" do
      before do
        Airbrake::Config.instance = Airbrake::Config.new(
          project_id: '1',
          workers: 0,
          queue_size: 1,
        )
      end

      it "doesn't send the exceeded notices to Airbrake" do
        15.times { subject.send(notice, Airbrake::Promise.new) }
        subject.close

        expect(a_request(:post, endpoint)).not_to have_been_made
      end

      it "returns a rejected promise" do
        promise = nil
        15.times do
          promise = subject.send(notice, Airbrake::Promise.new)
        end
        subject.close

        expect(promise).to be_rejected
        expect(promise.value).to eq(
          'error' => "AsyncSender has reached its capacity of 1",
        )
      end
    end
  end
end
