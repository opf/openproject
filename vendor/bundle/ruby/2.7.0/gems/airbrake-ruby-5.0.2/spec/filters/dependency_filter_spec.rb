RSpec.describe Airbrake::Filters::DependencyFilter do
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  describe "#call" do
    it "attaches loaded dependencies to context/versions/dependencies" do
      subject.call(notice)
      expect(notice[:context][:versions][:dependencies]).to include(
        'airbrake-ruby' => Airbrake::AIRBRAKE_RUBY_VERSION,
      )
    end
  end
end
