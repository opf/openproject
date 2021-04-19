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

describe ::API::V3::Configuration::ConfigurationRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  subject { representer.to_json }

  let(:represented) { Setting }
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |user|
      allow(user)
        .to receive(:preference)
        .and_return(FactoryBot.build_stubbed(:user_preference))
    end
  end
  let(:embed_links) { false }
  let(:representer) do
    described_class.new(represented, current_user: current_user, embed_links: embed_links)
  end
  let(:setting_max_updated_at) { DateTime.now }

  before do
    allow(Setting)
      .to receive(:maximum)
      .with(:updated_at)
      .and_return(setting_max_updated_at)
  end

  describe '_links' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.configuration }
    end

    context 'userPreferences' do
      context 'if logged in' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'userPreferences' }
          let(:href) { api_v3_paths.my_preferences }
        end
      end

      context 'if not logged in' do
        let(:current_user) { FactoryBot.build_stubbed(:anonymous) }

        it_behaves_like 'has an untitled link' do
          let(:link) { 'userPreferences' }
          let(:href) { api_v3_paths.my_preferences }
        end
      end
    end
  end

  describe 'properties' do
    describe '_type' do
      it_behaves_like 'property', :_type do
        let(:value) { 'Configuration' }
      end
    end

    describe 'updatedAt' do
      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { setting_max_updated_at }
        let(:json_path) { 'updatedAt' }
      end
    end

    describe 'maximumAttachmentFileSize', with_settings: { attachment_max_size: '1024' } do
      it_behaves_like 'property', :maximumAttachmentFileSize do
        let(:value) { 1024 * 1024 }
      end
    end

    describe 'perPageOptionse', with_settings: { per_page_options: '1, 50 ,   100  ' } do
      it_behaves_like 'property', :perPageOptions do
        let(:value) { [1, 50, 100] }
      end
    end

    describe 'timeFormat' do
      context 'with time format', with_settings: { time_format: '%I:%M %p' } do
        it 'indicates the timeFormat' do
          is_expected
            .to be_json_eql('hh:mm a'.to_json)
            .at_path('timeFormat')
        end
      end

      context 'with time format', with_settings: { time_format: '%H:%M' } do
        it 'indicates the timeFormat' do
          is_expected
            .to be_json_eql('HH:mm'.to_json)
            .at_path('timeFormat')
        end
      end

      context 'with a time format', with_settings: { time_format: '' } do
        it 'indicates the timeFormat' do
          is_expected
            .to be_json_eql(nil.to_json)
            .at_path('timeFormat')
        end
      end
    end

    describe 'dateFormat' do
      context 'without a date format', with_settings: { date_format: '' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql(nil.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%Y-%m-%d)', with_settings: { date_format: '%Y-%m-%d' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('YYYY-MM-DD'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%d/%m/%Y)', with_settings: { date_format: '%Y-%m-%d' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('YYYY-MM-DD'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%d.%m.%Y)', with_settings: { date_format: '%d.%m.%Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('DD.MM.YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%d-%m-%Y)', with_settings: { date_format: '%d-%m-%Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('DD-MM-YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%m/%d/%Y)', with_settings: { date_format: '%m/%d/%Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('MM/DD/YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%d %b %Y)', with_settings: { date_format: '%d %b %Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('DD MMM YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%d %B %Y)', with_settings: { date_format: '%d %B %Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('DD MMMM YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%b %d, %Y)', with_settings: { date_format: '%b %d, %Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('MMM DD, YYYY'.to_json)
            .at_path('dateFormat')
        end
      end

      context 'with date format (%B %d, %Y)', with_settings: { date_format: '%B %d, %Y' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql('MMMM DD, YYYY'.to_json)
            .at_path('dateFormat')
        end
      end
    end

    describe 'startOfWeek' do
      context 'without a setting', with_settings: { start_of_week: '' } do
        it 'is null' do
          is_expected
            .to be_json_eql(nil.to_json)
            .at_path('startOfWeek')
        end
      end

      context 'with `Monday` being set', with_settings: { start_of_week: '1' } do
        it 'indicates the dateFormat' do
          is_expected
            .to be_json_eql(1.to_json)
            .at_path('startOfWeek')
        end
      end
    end

    Setting.available_settings.each do |name, config|
      next unless %w(boolean).include?(config['format'])

      describe name, with_settings: { name => true } do
        it_behaves_like 'property', name.camelize(:lower).to_sym do
          let(:value) { true }
        end
      end
    end
  end

  describe '_embedded' do
    context 'userPreferences' do
      context 'if embedding' do
        let(:embed_links) { true }

        it 'embedds the user preferences' do
          is_expected
            .to be_json_eql('UserPreferences'.to_json)
            .at_path('_embedded/userPreferences/_type')
        end
      end

      context 'if not embedding' do
        it 'embedds the user preferences' do
          is_expected
            .not_to have_json_path('_embedded/userPreferences/_type')
        end
      end
    end
  end
end
