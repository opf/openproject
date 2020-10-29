RSpec.describe Airbrake::Config::Processor do
  let(:notifier) { Airbrake::NoticeNotifier.new }

  describe "#process_blocklist" do
    let(:config) { Airbrake::Config.new(blocklist_keys: %w[a b c]) }

    context "when there ARE blocklist keys" do
      it "adds the blocklist filter" do
        described_class.new(config).process_blocklist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysBlocklist)).to eq(true)
      end
    end

    context "when there are NO blocklist keys" do
      let(:config) { Airbrake::Config.new(blocklist_keys: %w[]) }

      it "doesn't add the blocklist filter" do
        described_class.new(config).process_blocklist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysBlocklist))
          .to eq(false)
      end
    end
  end

  describe "#process_allowlist" do
    let(:config) { Airbrake::Config.new(allowlist_keys: %w[a b c]) }

    context "when there ARE allowlist keys" do
      it "adds the allowlist filter" do
        described_class.new(config).process_allowlist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysAllowlist)).to eq(true)
      end
    end

    context "when there are NO allowlist keys" do
      let(:config) { Airbrake::Config.new(allowlist_keys: %w[]) }

      it "doesn't add the allowlist filter" do
        described_class.new(config).process_allowlist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysAllowlist))
          .to eq(false)
      end
    end
  end

  describe "#process_remote_configuration" do
    context "when the config doesn't define a project_id" do
      let(:config) { Airbrake::Config.new(project_id: nil) }

      it "doesn't set remote settings" do
        expect(Airbrake::RemoteSettings).not_to receive(:poll)
        described_class.new(config).process_remote_configuration
      end
    end

    context "when the config defines a project_id" do
      let(:config) do
        Airbrake::Config.new(project_id: 123)
      end

      it "sets remote settings" do
        expect(Airbrake::RemoteSettings).to receive(:poll)
        described_class.new(config).process_remote_configuration
      end
    end
  end

  describe "#add_filters" do
    context "when there's a root directory" do
      let(:config) { Airbrake::Config.new(root_directory: '/abc') }

      it "adds RootDirectoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::RootDirectoryFilter))
          .to eq(true)
      end

      it "adds GitRevisionFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRevisionFilter))
          .to eq(true)
      end

      it "adds GitRepositoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRepositoryFilter))
          .to eq(true)
      end

      it "adds GitLastCheckoutFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitLastCheckoutFilter))
          .to eq(true)
      end
    end

    context "when there's NO root directory" do
      let(:config) { Airbrake::Config.new(root_directory: nil) }

      it "doesn't add RootDirectoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::RootDirectoryFilter))
          .to eq(false)
      end

      it "doesn't add GitRevisionFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRevisionFilter))
          .to eq(false)
      end

      it "doesn't add GitRepositoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRepositoryFilter))
          .to eq(false)
      end

      it "doesn't add GitLastCheckoutFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitLastCheckoutFilter))
          .to eq(false)
      end
    end
  end
end
