#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject
  describe I18n, type: :helper do
    include Redmine::I18n

    let(:format) { '%d/%m/%Y' }
    let(:user) { FactoryBot.build_stubbed :user }

    after do
      Time.zone = nil
    end

    describe 'with user time zone' do
      before do
        login_as user
        allow(user).to receive(:time_zone).and_return(ActiveSupport::TimeZone['Athens'])
      end
      it 'returns a date in the user timezone for a utc timestamp' do
        Time.zone = 'UTC'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq '01/07/2013'
      end

      it 'returns a date in the user timezone for a non-utc timestamp' do
        Time.zone = 'Berlin'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq '01/07/2013'
      end
    end

    describe 'without user time zone' do
      before do allow(User.current).to receive(:time_zone).and_return(nil) end

      it 'returns a date in the local system timezone for a utc timestamp' do
        Time.zone = 'UTC'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        allow(time).to receive(:localtime).and_return(ActiveSupport::TimeZone['Athens'].local(2013, 07, 01, 01, 59))
        expect(format_time_as_date(time, format)).to eq '01/07/2013'
      end

      it 'returns a date in the original timezone for a non-utc timestamp' do
        Time.zone = 'Berlin'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq '30/06/2013'
      end
    end

    describe 'all_languages' do
      # Those are the two languages we support
      it 'includes en' do
        expect(all_languages).to include(:en)
      end
      it 'includes de' do
        expect(all_languages).to include(:de)
      end

      it 'should return no js language as they are duplicates of the rest of the other language' do
        expect(all_languages.any? { |l| /\Ajs-/.match(l.to_s) }).to be_falsey
      end

      # it is OK if more languages exist
      it 'has multiple languages' do
        expect(all_languages).to include :en, :de, :fr, :es
        expect(all_languages.size).to be >= 25
      end
    end

    describe 'valid_languages' do
      it 'allows only languages that are available' do
        allow(Setting).to receive(:available_languages).and_return([:en])

        expect(valid_languages).to eql [:en]
      end

      it 'allows only languages that exist' do
        allow(Setting).to receive(:available_languages).and_return([:'123'])

        expect(valid_languages).to be_empty
      end
    end

    describe 'set_language_if_valid' do
      before do
        allow(Setting).to receive(:available_languages).and_return(Setting.all_languages)
      end

      Setting.all_languages.each do |lang|
        it "should set I18n.locale to #{lang}" do
          allow(I18n).to receive(:locale=)
          expect(I18n).to receive(:locale=).with(lang)

          set_language_if_valid(lang)
        end
      end

      it 'should not set I18n.locale to an invalid language' do
        allow(Setting).to receive(:available_languages).and_return([:en])

        expect(I18n).not_to receive(:locale=).with(:de)
      end
    end

    describe 'find_language' do
      before do
        allow(Setting).to receive(:available_languages).and_return([:de])
      end

      it 'is nil if language is not active' do
        expect(find_language(:en)).to be_nil
      end

      it 'is nil if no language is given' do
        expect(find_language('')).to be_nil
        expect(find_language(nil)).to be_nil
      end

      it 'is the language if it is active' do
        expect(find_language(:de)).to eql :de
      end

      it 'can be found by uppercase if it is active' do
        expect(find_language(:DE)).to eql :de
      end

      it 'is nil if non valid string is passed' do
        expect(find_language('*')).to be_nil
        expect(find_language('78445')).to be_nil
        expect(find_language('/)(')).to be_nil
      end
    end

    describe 'link_translation' do
      let(:locale) { :en }
      let(:urls) {
        { url_1: 'http://openproject.com/foobar', url_2: '/baz' }
      }

      before do
        allow(::I18n)
          .to receive(:t)
          .with('translation_with_a_link', locale: locale)
          .and_return('There is a [link](url_1) in this translation! Maybe even [two](url_2)?')
      end

      it 'allows to insert links into translations' do
        translated = link_translate :translation_with_a_link, links: urls

        expect(translated).to eq(
          "There is a <a href=\"http://openproject.com/foobar\">link</a> in this translation!" +
          " Maybe even <a href=\"/baz\">two</a>?")
      end

      context 'with locale' do
        let(:locale) { :de }
        it 'uses the passed locale' do
          translated = link_translate :translation_with_a_link, links: urls, locale: locale

          expect(translated).to eq(
            "There is a <a href=\"http://openproject.com/foobar\">link</a> in this translation!" +
            " Maybe even <a href=\"/baz\">two</a>?")
        end
      end
    end

    describe '#format_date' do
      context 'without a date_format setting', with_settings: { date_format: '' } do
        it 'uses the locale formate' do
          expect(format_date(Date.today))
            .to eql I18n.l(Date.today)
        end
      end

      context 'with a date_format setting', with_settings: { date_format: '%d %m %Y' } do
        it 'adheres to the format' do
          expect(format_date(Date.today))
            .to eql Date.today.strftime('%d %m %Y')
        end
      end
    end
  end
end
