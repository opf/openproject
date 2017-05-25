require 'spec_helper'

describe PluginManager do
  before do
    allow(described_class).to receive(:system)
  end

  describe '#add' do
    let(:plugin_manager) { described_class.new('test-environment') }

    before do
      allow(plugin_manager).to receive(:_gemfile_plugins).and_return('')
    end

    context 'with a plugin that is already installed' do
      let(:plugin) { 'test' }
      before do
        plugin_manager.instance_variable_set(:@gemfile_plugins, plugin)
      end

      it 'exits' do
        expect { plugin_manager.add(plugin) }.to raise_error SystemExit
      end
    end

    context 'with a plugin that is not already installed' do
      let(:count_of_plugin) {
        plugin_manager.instance_variable_get(:@gemfile_plugins).scan(/#{plugin_to_add}.*/).count
      }
      let(:gemfile_plugins) { plugin_manager.instance_variable_get(:@gemfile_plugins) }
      let(:plugin_to_add) { 'test' }
      let(:url) { 'test-url' }
      let(:branch) { 'test-branch' }
      let(:dependency) { 'dependency' }
      let(:plugin_specs) {
        {
          plugin_to_add => {
            url: url,
            branch: branch,
            dependencies: [dependency]
          },
          dependency => {
            url: '',
            branch: '',
            dependencies: [plugin_to_add]
          }
        }
      }

      before do
        allow(Plugin).to receive(:available_plugins).and_return(plugin_specs)
        plugin_manager.instance_variable_set(:@gemfile_plugins, '')
        allow(plugin_manager).to receive(:_bundle)
        allow(plugin_manager).to receive(:_migrate)
        allow(plugin_manager).to receive(:_assets_webpack)
        allow(plugin_manager).to receive(:_write_to_gemfile_plugins_file)
        plugin_manager.add(plugin_to_add)
      end

      it 'does not add a plugin twice' do
        expect(count_of_plugin).to eql(1)
      end

      it 'contains the url of the plugin' do
        expect(gemfile_plugins).to include(url)
      end

      it 'contains the url of the plugin' do
        expect(gemfile_plugins).to include(branch)
      end
    end
  end

  describe '#remove' do
    context 'with a plugin that is not installed' do
      let(:plugin_manager) { described_class.new('test-environment') }

      before do
        plugin_manager.instance_variable_set(:@gemfile_plugins, '')
      end

      it 'exits' do
        expect { plugin_manager.remove('test') }.to raise_error SystemExit
      end
    end

    context 'with a plugin that is installed' do
      subject(:gemfile_plugins_new) {
        plugin_manager.instance_variable_get(:@gemfile_plugins)
      }
      let(:plugin_manager) { described_class.new('test-environment') }
      let(:plugin_to_delete) { 'plugin_to_delete' }
      let(:other_plugin) { 'other_plugin' }
      let(:independent_plugin) { 'independent_plugin' }
      let(:plugin_specs) {
        {
          plugin_to_delete => {
            url: '',
            branch: '',
          },
          other_plugin => {
            url: '',
            branch: '',
          },
          independent_plugin => {
            url: '',
            branch: '',
          }
        }
      }
      let(:gemfile_plugins) {
        "#{other_plugin}\n#{independent_plugin}"
      }

      before do
        allow(Plugin).to receive(:available_plugins).and_return(plugin_specs)
        plugin_manager.instance_variable_set(:@gemfile_plugins, gemfile_plugins)
        allow(plugin_manager).to receive(:_bundle)
        allow(plugin_manager).to receive(:_revert_migrations)
        allow(plugin_manager).to receive(:_write_to_gemfile_plugins_file)
        allow(plugin_manager).to receive(:_remove_gemfile_plugins_if_empty)

        plugin_manager.remove(plugin_to_delete)
      end

      it 'does not remove independent plugins' do
        expect(gemfile_plugins_new).to include(independent_plugin)
      end

      it 'does not remove plugins that could have been installed before' do
        expect(gemfile_plugins_new).to include(other_plugin)
      end

      it 'removes the plugin' do
        expect(gemfile_plugins_new).not_to include(plugin_to_delete)
      end
    end
  end
end

describe Plugin do
  describe '.available?' do
    subject { described_class.available?(plugin) }
    let(:plugin) { 'test' }

    context 'with a non-existent plugin' do
      it 'returns false' do
        allow(described_class).to receive(:available_plugins).and_return({})
        is_expected.to be_falsey
      end
    end

    context 'with an existent plugin' do
      it 'returns true' do
        allow(described_class).to receive(:available_plugins).and_return(plugin => :test)
        is_expected.to be_truthy
      end
    end
  end

  describe '.available_plugins'do
    context 'with nullified instance variable' do
      let(:test_string) { 'test-string' }

      before(:each) do
        described_class.instance_variable_set(:@available_plugins, nil)
      end

      it 'loads the correct yml file' do
        expect(YAML).to receive(:load_file).with(described_class::PLUGINS_YML_PATH).and_return({})
        described_class.available_plugins
      end

      it 'sets the instance variable to the correct value' do
        allow(YAML).to receive(:load_file).and_return(test_string)
        described_class.available_plugins
        expect(described_class.instance_variable_get(:@available_plugins)).to eql(test_string)
      end
    end
  end

  describe '#initialize' do
    context 'with an unavailable plugin' do
      before do
        allow(described_class).to receive(:available?).and_return(false)
      end

      it 'exits' do
        expect { described_class.new('test') }.to raise_error SystemExit
      end
    end

    context 'with an available plugin' do
      subject { described_class.new(plugin).name }
      let(:plugin) { 'test' }

      before do
        allow(described_class).to receive(:available?).and_return(true)
      end

      it 'saves the name' do
        is_expected.to eql(plugin)
      end
    end
  end

  describe '#included_in?' do
    subject { plugin.included_in?(string) }
    let(:plugin) { described_class.new('test') }

    before do
      allow(described_class).to receive(:available?).and_return(true)
    end

    context 'with a string that does not contain the name of the plugin' do
      let(:string) { '' }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'with a string that does contain the name of the plugin' do
      let(:string) { 'test' }

      it 'returns false' do
        is_expected.to be_truthy
      end
    end
  end

  describe '#gemfile_plugins_line' do
    subject { plugin.gemfile_plugins_line }
    let(:plugin) { described_class.new(plugin_name) }
    let(:plugin_name) { 'test' }

    before do
      allow(described_class).to receive(:available?).and_return(true)
      allow(described_class).to receive(:available_plugins).and_return(plugin_specs)
    end

    context 'with a plugin with url and branch key' do
      let(:url) { 'test-url' }
      let(:branch) { 'test-branch' }
      let(:plugin_specs) {
        {
          plugin_name =>
          {
            url: url,
            branch: branch
          }
        }
      }

      it 'contains the name of the plugin' do
        is_expected.to include("gem \"#{plugin_name}\"")
      end

      it 'contains the url identifier' do
        is_expected.to include("git: \"#{url}\"")
      end

      it 'contains the branch identifier' do
        is_expected.to include("branch: \"#{branch}\"")
      end
    end

    context 'with a plugin with version key' do
      let(:version) { 'test-version' }
      let(:plugin_specs) { { plugin_name => { version: version } } }

      it 'contains the version' do
        is_expected.to include(version)
      end
    end
  end
end

