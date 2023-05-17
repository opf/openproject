# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe Source::SeedDataLoader do
  let(:title_en) { 'Welcome to OpenProject' }
  let(:text_en) { 'Learn how to plan projects efficiently.' }
  let(:title_fr) { 'Bienvenue sur OpenProject' }
  let(:text_fr) { 'Apprenez à planifier des projets efficacement.' }
  let(:locale) { 'fr' }
  let(:seed_file_name) { 'special_edition' }

  subject(:loader) { described_class.new(seed_file_name:, locale:) }

  def mock_translations(locale, translations_map)
    translations_map.each do |key, translation|
      allow(I18n).to receive(:t).with(key, hash_including(locale: locale.to_s)).and_return(translation)
      allow(I18n).to receive(:t).with(key, hash_including(locale: locale.to_sym)).and_return(translation)
    end
  end

  before do
    allow(I18n).to receive(:t).and_call_original
  end

  describe '#translate' do
    it 'translates keys with a "t_" prefix' do
      mock_translations(
        locale,
        "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.welcome.title" => title_fr,
        "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.welcome.text" => text_fr
      )
      hash = {
        'welcome' => {
          't_title' => title_en,
          't_text' => text_en,
          'icon' => ':smile:'
        }
      }

      translated = loader.translate(hash)
      expect(translated.dig('welcome', 'title')).to eq(title_fr)
      expect(translated.dig('welcome', 'text')).to eq(text_fr)
      expect(translated.dig('welcome', 'icon')).to eq(':smile:')
    end

    it 'translates nothing if prefix "t_" is absent' do
      mock_translations(
        locale,
        "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.welcome.title" => title_fr,
        "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.welcome.text" => text_fr
      )
      hash = {
        'welcome' => {
          'title' => title_en,
          'text' => text_en
        }
      }

      translated = loader.translate(hash)
      expect(I18n).not_to have_received(:t)
      expect(translated.dig('welcome', 'title')).to eq(title_en)
      expect(translated.dig('welcome', 'text')).to eq(text_en)
    end

    it 'uses the original string if no translation exists' do
      hash = {
        'welcome' => {
          't_title' => title_en,
          't_text' => text_en
        }
      }

      translated = loader.translate(hash)

      expect(I18n).to have_received(:t).at_least(:twice)
      expect(translated.dig('welcome', 'title')).to eq(title_en)
      expect(translated.dig('welcome', 'text')).to eq(text_en)
    end

    it 'removes the prefixed keys from the returned hash' do
      hash = {
        'welcome' => {
          't_title' => title_en,
          't_text' => text_en
        }
      }

      translated = loader.translate(hash)
      expect(translated['welcome']).to eq(
        'title' => title_en,
        'text' => text_en
      )
    end

    context 'when the value to translate is an array' do
      let(:locale) { 'de' }

      it 'translates each values using indices' do
        mock_translations(
          locale,
          "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.categories.item_0" => 'Erste Kategorie',
          "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.categories.item_1" => 'Zweite Kategorie'
        )
        hash = {
          't_categories' => [
            'First category',
            'Second category',
            'Missing translations are kept as-is'
          ]
        }

        translated = loader.translate(hash)
        expect(translated['categories'])
          .to eq(['Erste Kategorie', 'Zweite Kategorie', 'Missing translations are kept as-is'])
      end
    end

    context 'when hash contains array of hashes' do
      it 'translates keys in the nested values if they have translatable keys' do
        mock_translations(
          locale,
          "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.queries.item_0.name" => 'Plan projet',
          "#{Source::Translate::I18N_PREFIX}.#{seed_file_name}.queries.item_1.name" => 'Tâches'
        )

        translated = loader.translate(
          'queries' => [
            { 't_name' => 'Project plan', 'open' => true },
            { 't_name' => 'Tasks', 'open' => true },
            { 't_name' => 'Missing translations are kept as-is', 'open' => true }
          ]
        )
        expect(translated['queries']).to eq(
          [
            { 'name' => 'Plan projet', 'open' => true },
            { 'name' => 'Tâches', 'open' => true },
            { 'name' => 'Missing translations are kept as-is', 'open' => true }
          ]
        )
      end
    end
  end
end
