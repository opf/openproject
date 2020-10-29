RSpec.describe Airbrake::Ignorable do
  let(:klass) do
    mod = subject
    Class.new { include(mod) }
  end

  it "ignores includee" do
    instance = klass.new
    expect(instance).not_to be_ignored

    instance.ignore!
    expect(instance).to be_ignored
  end
end
