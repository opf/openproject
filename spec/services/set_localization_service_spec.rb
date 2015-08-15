#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe SetLocalizationService do
  let(:user) { FactoryGirl.build_stubbed(:user, language: user_language) }
  let(:http_accept_header) { "#{http_accept_language},en-US;q=0.8,en;q=0.6" }
  let(:instance) { described_class.new(user, http_accept_header) }
  let(:user_language) { :bogus_language }
  let(:http_accept_language) { :http_accept_language }
  let(:default_language) { :default_language }

  before do
    allow(I18n).to receive(:locale=).with(:en)
    allow(instance).to receive(:valid_languages).and_return [user_language,
                                                             http_accept_language,
                                                             default_language]
    allow(Setting).to receive(:default_language).and_return(default_language)
  end

  def expect_locale(locale)
    expect(I18n).to receive(:locale=).with(locale)
  end

  shared_examples_for 'falls back to the header' do
    it 'falls back to the header' do
      expect_locale(http_accept_language)

      instance.call
    end
  end

  shared_examples_for "falls back to the instane's default language" do
    it "falls back to the instance's default language" do
      expect_locale(default_language)

      instance.call
    end
  end

  context 'for a logged in user' do
    it "sets the language to the user's selected language" do
      expect_locale(user_language)

      instance.call
    end

    context 'with the language not being valid' do
      before do
        allow(instance).to receive(:valid_languages).and_return [http_accept_language,
                                                                 default_language]
      end

      it_behaves_like 'falls back to the header'
    end

    context 'with the user not having a language selected' do
      before do
        user.language = nil
      end

      it_behaves_like 'falls back to the header'

      context 'with the header not being valid' do
        before do
          allow(instance).to receive(:valid_languages).and_return [user_language,
                                                                   default_language]
        end

        it_behaves_like "falls back to the instane's default language"
      end

      context 'with no header set' do
        let(:http_accept_header) { nil }

        it_behaves_like "falls back to the instane's default language"
      end
    end
  end

  context 'for an anonymous user' do
    let(:user) { FactoryGirl.build_stubbed(:anonymous) }

    it_behaves_like 'falls back to the header'

    context 'with no header set' do
      let(:http_accept_header) { nil }

      it_behaves_like "falls back to the instane's default language"
    end
  end
end
