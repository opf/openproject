#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Settings::Definition do
  shared_context 'clean definitions' do
    let!(:definitions_before) { described_class.all.dup }

    before do
      described_class.send(:reset)
    end

    after do
      described_class.send(:reset)
      described_class.instance_variable_set(:@all, definitions_before)
    end
  end

  describe '.all' do
    subject(:all) { described_class.all }

    it "is a list of setting definitions" do
      expect(all)
        .to be_all { |d| d.is_a?(Settings::Definition) }
    end

    it 'contains a definition from settings' do
      expect(all)
        .to be_any { |d| d.name == 'smtp_address' }
    end

    it 'contains a definition from configuration' do
      expect(all)
        .to be_any { |d| d.name == 'edition' }
    end

    it 'contains a definition from settings.yml' do
      expect(all)
        .to be_any { |d| d.name == 'sendmail_location' }
    end

    it 'casts the value from settings.yml' do
      expect(all.detect { |d| d.name == 'brute_force_block_after_failed_logins' }.value)
        .to eql 20
    end

    context 'when overriding from ENV' do
      include_context 'clean definitions'

      it 'allows overriding configuration from ENV' do
        stub_const('ENV', { 'OPENPROJECT_EDITION' => 'foo' })

        expect(all.detect { |d| d.name == 'edition' }.value)
          .to eql 'foo'
      end

      it 'overriding configuration from ENV will set it to non writable' do
        stub_const('ENV', { 'OPENPROJECT_EDITION' => 'foo' })

        expect(all.detect { |d| d.name == 'edition' })
          .not_to be_writable
      end

      it 'allows overriding settings array from ENV' do
        stub_const('ENV', { 'OPENPROJECT_PASSWORD__ACTIVE__RULES' => YAML.dump(['lowercase']) })

        expect(all.detect { |d| d.name == 'password_active_rules' }.value)
          .to eql ['lowercase']
      end

      it 'overriding settings from ENV will set it to non writable' do
        stub_const('ENV', { 'OPENPROJECT_WELCOME__TITLE' => 'Some title' })

        expect(all.detect { |d| d.name == 'welcome_title' })
          .not_to be_writable
      end

      it 'allows overriding settings hash partially from ENV' do
        stub_const('ENV', { 'OPENPROJECT_REPOSITORY__CHECKOUT__DATA_GIT_ENABLED' => '1' })

        expect(all.detect { |d| d.name == 'repository_checkout_data' }.value)
          .to eql({
                    'git' => { 'enabled' => 1 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'ENV vars for which no definition exists will not be handled' do
        stub_const('ENV', { 'OPENPROJECT_BOGUS' => '1' })

        expect(all.detect { |d| d.name == 'bogus' })
          .to be_nil
      end
    end

    context 'when overriding from file' do
      include_context 'clean definitions'

      let(:file_contents) do
        {
          'default' => {
            'edition' => 'default edition',
            'sendmail_location' => 'default location'
          },
          'test' => {
            'smtp_address' => 'test address',
            'sendmail_location' => 'test location',
            'bogus' => 'bogusvalue'
          }
        }
      end

      before do
        allow(YAML)
          .to receive(:load_file)
          .with(Rails.root.join('config/configuration.yml'))
          .and_return(file_contents)

        allow(File)
          .to receive(:file?)
          .with(Rails.root.join('config/configuration.yml'))
          .and_return(true)
      end

      it 'overrides from file default' do
        expect(all.detect { |d| d.name == 'edition' }.value)
          .to eql 'default edition'
      end

      it 'marks the value overwritten from file default unwritable' do
        expect(all.detect { |d| d.name == 'edition' })
          .not_to be_writable
      end

      it 'overrides from file default path but once again from current env' do
        expect(all.detect { |d| d.name == 'sendmail_location' }.value)
          .to eql 'test location'
      end

      it 'marks the value overwritten from file default and again from current unwritable' do
        expect(all.detect { |d| d.name == 'sendmail_location' })
          .not_to be_writable
      end

      it 'overrides from file current env' do
        expect(all.detect { |d| d.name == 'smtp_address' }.value)
          .to eql 'test address'
      end

      it 'marks the value overwritten from file current unwritable' do
        expect(all.detect { |d| d.name == 'smtp_address' })
          .not_to be_writable
      end

      it 'does not accept undefined settings' do
        expect(all.detect { |d| d.name == 'bogus' })
          .to eql nil
      end

      context 'when overwritten from ENV' do
        before do
          stub_const('ENV', { 'OPENPROJECT_SENDMAIL__LOCATION' => 'env location' })
        end

        it 'overrides from ENV' do
          expect(all.detect { |d| d.name == 'sendmail_location' }.value)
            .to eql 'env location'
        end

        it 'marks the overwritten value unwritable' do
          expect(all.detect { |d| d.name == 'sendmail_location' })
            .not_to be_writable
        end
      end
    end

    context 'when adding an additional setting' do
      include_context 'clean definitions'

      it 'includes the setting' do
        all

        described_class.add 'bogus',
                            value: 1,
                            format: :integer

        expect(all.detect { |d| d.name == 'bogus' }.value)
          .to eql(1)
      end
    end
  end

  describe ".[name]" do
    subject(:definition) { described_class[key] }

    context 'with a string' do
      let(:key) { 'smtp_address' }

      it 'returns the value' do
        expect(definition.name)
          .to eql key
      end
    end

    context 'with a symbol' do
      let(:key) { :smtp_address }

      it 'returns the value' do
        expect(definition.name)
          .to eql key.to_s
      end
    end

    context 'with a non existing key' do
      let(:key) { 'bogus' }

      it 'returns the value' do
        expect(definition)
          .to be_nil
      end
    end

    context 'when adding a setting late' do
      include_context 'clean definitions'
      let(:key) { 'bogus' }

      before do
        described_class[key]

        described_class.add 'bogus',
                            value: 1,
                            format: :integer
      end

      it 'has the setting' do
        expect(definition.name)
          .to eql key.to_s
      end
    end
  end

  describe '#override_value' do
    let(:format) { :string }
    let(:value) { 'abc' }

    let(:instance) do
      described_class
        .new 'bogus',
             format: format,
             value: value
    end

    context 'with string format' do
      before do
        instance.override_value('xyz')
      end

      it 'overwrites' do
        expect(instance.value)
          .to eql 'xyz'
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end

    context 'with hash format' do
      let(:format) { :hash }
      let(:value) do
        {
          abc: {
            a: 1,
            b: 2
          },
          cde: 1
        }
      end

      before do
        instance.override_value({ abc: { a: 5 }, xyz: 2 })
      end

      it 'deep merges' do
        expect(instance.value)
          .to eql({
                    abc: {
                      a: 5,
                      b: 2
                    },
                    cde: 1,
                    xyz: 2
                  })
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end

    context 'with array format' do
      let(:format) { :array }
      let(:value) { [1, 2, 3] }

      before do
        instance.override_value([4, 5, 6])
      end

      it 'overwrites' do
        expect(instance.value)
          .to eql [4, 5, 6]
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end
  end

  describe '.exists?' do
    context 'with an existing setting' do
      it 'is truthy' do
        expect(described_class)
          .to exist('smtp_address')
      end
    end

    context 'with a non existing setting' do
      it 'is truthy' do
        expect(described_class)
          .not_to exist('foobar')
      end
    end
  end

  describe '.new' do
    context 'with all the attributes' do
      let(:instance) do
        described_class.new 'bogus',
                            format: :integer,
                            value: 1,
                            api_name: 'boGus',
                            serialized: true,
                            api: false,
                            admin: false,
                            writable: false
      end

      it 'has the name' do
        expect(instance.name)
          .to eql 'bogus'
      end

      it 'has the format (in symbol)' do
        expect(instance.format)
          .to eql :integer
      end

      it 'has the value' do
        expect(instance.value)
          .to eql 1
      end

      it 'has the api_name' do
        expect(instance.api_name)
          .to eql 'boGus'
      end

      it 'has the serialized' do
        expect(instance.serialized)
          .to eql true
      end

      it 'has the api' do
        expect(instance.api)
          .to eql false
      end

      it 'has the admin value' do
        expect(instance.admin)
          .to eql false
      end

      it 'has the writable value' do
        expect(instance.writable)
          .to eql false
      end
    end

    context 'with the minimal attributes (integer value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: 1
      end

      it 'has the name' do
        expect(instance.name)
          .to eql 'bogus'
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :integer
      end

      it 'has the value' do
        expect(instance.value)
          .to eql 1
      end

      it 'has the api_name' do
        expect(instance.api_name)
          .to eql 'bogus'
      end

      it 'has the serialized' do
        expect(instance.serialized)
          .to eql false
      end

      it 'has the api' do
        expect(instance.api)
          .to eql true
      end

      it 'has the admin value' do
        expect(instance.admin)
          .to eql true
      end

      it 'has the writable value' do
        expect(instance.writable)
          .to eql true
      end
    end

    context 'with the minimal attributes (hash value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: { a: 'b' }
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :hash
      end
    end

    context 'with the minimal attributes (array value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: [:a, :b]
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :array
      end
    end

    context 'with the minimal attributes (true value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: true
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :boolean
      end
    end

    context 'with the minimal attributes (false value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: false
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :boolean
      end
    end

    context 'with the minimal attributes (date value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: Date.today
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :date
      end
    end

    context 'with the minimal attributes (datetime value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: DateTime.now
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :date_time
      end
    end

    context 'with the minimal attributes (string value)' do
      let(:instance) do
        described_class.new 'bogus',
                            value: 'abc'
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eql :string
      end
    end
  end
end
