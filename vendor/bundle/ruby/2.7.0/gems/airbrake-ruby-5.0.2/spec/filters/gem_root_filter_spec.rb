RSpec.describe Airbrake::Filters::GemRootFilter do
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }
  let(:root1) { '/my/gem/root' }
  let(:root2) { '/my/other/gem/root' }

  before { Gem.path << root1 << root2 }
  after { 2.times { Gem.path.pop } }

  it "replaces gem root in the backtrace with a label" do
    # rubocop:disable Layout/LineLength
    notice[:errors].first[:backtrace] = [
      { file: "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb" },
      { file: "#{root1}/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb" },
      { file: "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb" },
      { file: "#{root2}/gems/rspec-core-3.3.2/exe/rspec" },
    ]
    # rubocop:enable Layout/LineLength

    subject.call(notice)

    # rubocop:disable Layout/LineLength
    expect(notice[:errors].first[:backtrace]).to(
      eq(
        [
          { file: "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb" },
          { file: "/GEM_ROOT/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb" },
          { file: "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb" },
          { file: "/GEM_ROOT/gems/rspec-core-3.3.2/exe/rspec" },
        ],
      ),
    )
    # rubocop:enable Layout/LineLength
  end

  it "does not filter file when it is nil" do
    expect(notice[:errors].first[:file]).to be_nil
    expect { subject.call(notice) }.not_to(
      change { notice[:errors].first[:file] },
    )
  end
end
