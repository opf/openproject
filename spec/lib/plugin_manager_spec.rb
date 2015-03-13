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
      before do
        plugin_manager.instance_variable_set(:@gemfile_plugins, 'test')
      end

      it 'exits' do
        expect{plugin_manager.add('test')}.to raise_error SystemExit
      end
    end

    context 'with a plugin that is not already installed' do
      subject(:count_of_test) {
        plugin_manager.instance_variable_get(:@gemfile_plugins).scan(/test.*/).count
      }
      let(:plugin_specs) {
        {
          'test' => {
            url: 'test-url',
            branch: 'test-branch',
            dependencies: ['dependency']
          },
          'dependency' => {
            url: 'dependency-url',
            branch: 'dependency-branch',
            dependencies: ['test']
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
      end

      it 'does not add a plugin twice' do
        plugin_manager.add('test')
        expect(count_of_test).to eql(1)
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
        expect{plugin_manager.remove('test')}.to raise_error SystemExit
      end
    end

    context 'with a plugin that is installed' do
      subject(:gemfile_plugins_new) {
        plugin_manager.instance_variable_get(:@gemfile_plugins)
      }
      let(:plugin_manager) { described_class.new('test-environment') }
      let(:plugin_to_delete) { 'plugin_to_delete' }
      let(:dependency_to_delete) { 'dependency_to_delete' }
      let(:shared_dependency) { 'shared_dependency' }
      let(:other_plugin) { 'other_plugin' }
      let(:plugin_specs) {
        {
          plugin_to_delete => {
            url: '',
            branch: '',
            dependencies: [dependency_to_delete, shared_dependency]
          },
          dependency_to_delete => {
            url: '',
            branch: '',
            dependencies: [plugin_to_delete]
          },
          shared_dependency => {
            url: '',
            branch: '',
          },
          other_plugin => {
            url: '',
            branch: '',
            dependencies: [shared_dependency]
          }
        }
      }
      let(:gemfile_plugins) {
        "#{plugin_to_delete}\n#{dependency_to_delete}\n#{shared_dependency}\n#{other_plugin}"
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

      it 'does not remove dependencies that are required by other plugins' do
        expect(gemfile_plugins_new).to include(shared_dependency)
      end

      it 'does not remove independent plugins' do
        expect(gemfile_plugins_new).to include(other_plugin)
      end

      it 'removes dependencies that are only required by this plugin' do
        expect(gemfile_plugins_new).not_to include(dependency_to_delete)

      end

      it 'removes the plugin' do
        expect(gemfile_plugins_new).not_to include(plugin_to_delete)
      end
    end
  end
end

describe Plugin do
  describe '.available?' do
    subject { described_class.available?('test') }

    context 'with a non-existent plugin' do
      it 'returns false' do
        allow(described_class).to receive(:available_plugins).and_return({})
        is_expected.to be_falsey
      end
    end

    context 'with an existent plugin' do
      it 'returns true' do
        allow(described_class).to receive(:available_plugins).and_return({'test' => :test})
        is_expected.to be_truthy
      end
    end
  end

  describe '.available_plugins'do
    context 'with nullified instance variable' do
      before(:each) do
        described_class.instance_variable_set(:@available_plugins, nil)
      end

      it 'loads the correct yml file' do
        expect(YAML).to receive(:load_file).with(described_class::PLUGINS_YML_PATH).and_return({})
        described_class.available_plugins
      end

      it 'sets the instance variable to the correct value' do
        allow(YAML).to receive(:load_file).and_return('test-string')
        described_class.available_plugins
        expect(described_class.instance_variable_get(:@available_plugins)).to eql('test-string')
      end
    end
  end

  describe '#initialize' do
    context 'with an unavailable plugin' do
      before do
        allow(described_class).to receive(:available?).and_return(false)
      end

      it 'exits' do
        expect{described_class.new('test')}.to raise_error SystemExit
      end
    end

    context 'with an available plugin' do
      subject {described_class.new('test').name}

      before do
        allow(described_class).to receive(:available?).and_return(true)
      end

      it 'saves the name' do
        is_expected.to eql('test')
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
    let(:plugin) { described_class.new('test') }

    before do
      allow(described_class).to receive(:available?).and_return(true)
      allow(described_class).to receive(:available_plugins).and_return(plugin_specs)
    end

    context 'with a plugin with url and branch key' do
      let(:url) { 'test-url' }
      let(:branch) { 'test-branch' }
      let(:plugin_specs) {
        {
          'test' =>
          {
            url: url,
            branch: branch
          }
        }
      }

      it 'contains the name of the plugin' do
        is_expected.to include("gem \"test\"")
      end

      it 'contains the url identifier' do
        is_expected.to include("git: \"#{url}\"")
      end

      it 'contains the branch identifier' do
        is_expected.to include("branch: \"#{branch}\"")
      end
    end

    context 'with a plugin with url and branch key' do
      let(:version) { 'test-version' }
      let(:plugin_specs) { { 'test' => { version: version } } }

      it 'contains the version' do
        is_expected.to include(version)
      end
    end
  end

  describe '#gemfile_plugins_lines_for_dependencies' do
    subject {plugin.gemfile_plugins_lines_for_dependencies}
    let(:plugin) { described_class.new('test') }
    let(:dep1) { described_class.new('dep1') }
    let(:dep2) { described_class.new('dep2') }
    let(:dependencies) { [dep1, dep2] }
    let(:version) { 'test-version' }
    let(:plugin_specs) {
      {
        'test' => { version: version },
        'dep1' => { version: version },
        'dep2' => { version: version }
      }
    }

    before do
      allow(described_class).to receive(:available?).and_return(true)
      allow(described_class).to receive(:available_plugins).and_return(plugin_specs)
      allow(plugin).to receive(:dependencies).and_return(dependencies)
    end

    it 'contains all dependencies'do
      dependencies.each do |dependency|
        is_expected.to include(dependency.name)
      end
    end

  end

  describe '#dependencies' do
    subject { plugin.dependencies.map(&:name) }
    let(:plugin) { described_class.new('test') }
    let(:available_plugins) {
      {
        'test' => {
          dependencies: ['dep1', 'dep2']
        }
      }
    }

    before do
      allow(described_class).to receive(:available?).and_return(true)
      allow(described_class).to receive(:available_plugins).and_return(available_plugins)
    end

    it 'contains the correct dependencies' do
      is_expected.to eql(['dep1', 'dep2'])
    end
  end
end
