#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe OpenProject::Configuration, :settings_reset do
  describe '.[setting]' do
    it 'fetches the value' do
      expect(described_class.app_title)
        .to eql('OpenProject')
    end
  end

  describe '.[setting]?' do
    it 'fetches the value' do
      expect(described_class.smtp_enable_starttls_auto?)
        .to be false
    end

    it 'works for non boolean settings as well (deprecated)' do
      expect(described_class.app_title?)
        .to be false
    end
  end

  describe '.[setting]=' do
    it 'raises an error' do
      expect { described_class.smtp_enable_starttls_auto = true }
        .to raise_error NoMethodError
    end
  end

  describe '.configure_cache' do
    let(:application_config) do
      Rails::Application::Configuration.new Rails.root
    end

    context 'with cache store already set' do
      before do
        application_config.cache_store = 'foo'
      end

      context 'with additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end
    end

    context 'without cache store already set' do
      before do
        application_config.cache_store = nil
        described_class.send(:configure_cache, application_config)
      end

      context 'with additional cache store configuration', with_config: { 'rails_cache_store' => 'bar' } do
        it 'changes the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration', with_config: { 'rails_cache_store' => nil } do
        before do
          described_class['rails_cache_store'] = nil
        end

        it 'defaults the cache store to :file_store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store.first).to eq(:file_store)
        end
      end
    end
  end

  describe '#direct_uploads?' do
    let(:value) { described_class.direct_uploads? }

    it 'is false by default' do
      expect(value).to be false
    end

    context 'with remote storage' do
      def self.storage(provider)
        {
          attachments_storage: :fog,
          fog: {
            credentials: {
              provider:
            }
          }
        }
      end

      context 'with AWS', with_config: storage('AWS') do
        it 'is true' do
          expect(value).to be true
        end
      end

      context 'with Azure', with_config: storage('azure') do
        it 'is false' do
          expect(value).to be false
        end
      end
    end
  end
end
