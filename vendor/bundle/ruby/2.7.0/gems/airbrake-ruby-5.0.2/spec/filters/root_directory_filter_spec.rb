RSpec.describe Airbrake::Filters::RootDirectoryFilter do
  subject { described_class.new(root_directory) }

  let(:root_directory) { '/var/www/project' }
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  it "replaces root directory in the backtrace with a label" do
    # rubocop:disable Layout/LineLength
    notice[:errors].first[:backtrace] = [
      { file: "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb" },
      { file: "#{root_directory}/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb " },
      { file: "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb" },
      { file: "#{root_directory}/gems/rspec-core-3.3.2/exe/rspec" },
    ]
    # rubocop:enable Layout/LineLength

    subject.call(notice)

    # rubocop:disable Layout/LineLength
    expect(notice[:errors].first[:backtrace]).to(
      eq(
        [
          { file: "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb" },
          { file: "/PROJECT_ROOT/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb " },
          { file: "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb" },
          { file: "/PROJECT_ROOT/gems/rspec-core-3.3.2/exe/rspec" },
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
