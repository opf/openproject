# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++
#

require 'spec_helper'

RSpec.describe Admin::Settings::LanguagesSettingsController do
  shared_let(:user) { create(:admin) }
  current_user { user }

  describe 'GET #show' do
    subject { get 'show' }

    describe 'permissions' do
      let(:fetch) { subject }

      it_behaves_like 'a controller action with require_admin'
    end

    it 'renders the language settings template' do
      subject

      expect(response).to be_successful
      expect(response).to render_template 'admin/settings/languages_settings/show', 'layouts/admin'
    end
  end

  describe 'PATCH #update' do
    subject { patch 'update', params: }

    let(:available_languages) { %w[en fr de] }
    let(:start_of_week) { 1 }
    let(:first_week_of_year) { 1 }
    let(:date_format) { Settings::Definition[:date_format].allowed.first }
    let(:time_format) { Settings::Definition[:time_format].allowed.first }
    let(:base_settings) do
      { available_languages:, start_of_week:, first_week_of_year:, date_format:, time_format: }
    end
    let(:params) { { settings: } }

    context 'with valid params' do
      let(:settings) { base_settings }

      it 'succeeds' do
        subject

        expect(response).to redirect_to action: :show
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
      end

      it 'sets language of users having a non-available language to the default language',
         with_settings: { available_languages: %w[en de ja], default_language: 'de' } do
        user_de = create(:user, language: 'de')
        user_en = create(:user, language: 'en')
        user_foo = create(:user, language: 'foo')
        user_fr = create(:user, language: 'fr')
        user_ja = create(:user, language: 'ja')

        subject

        expect(user_de.reload.language).to eq('de')
        expect(user_en.reload.language).to eq('en')
        expect(user_foo.reload.language).to eq('de')
        expect(user_fr.reload.language).to eq('de')
        expect(user_ja.reload.language).to eq('ja')
      end
    end

    shared_examples 'invalid combination of start_of_week and first_week_of_year' do |missing_param:|
      provided_param = (%i[start_of_week first_week_of_year] - [missing_param]).first

      context "when setting only #{provided_param} but not #{missing_param}" do
        let(:settings) { base_settings.except(missing_param) }

        it 'redirects and sets the flash error' do
          subject

          expect(response).to redirect_to action: :show
          expect(flash[:error])
            .to eq(I18n.t('settings.display.first_date_of_week_and_year_set',
                          first_week_setting_name: I18n.t(:setting_first_week_of_year),
                          day_of_week_setting_name: I18n.t(:setting_start_of_week)))
        end
      end
    end

    include_examples 'invalid combination of start_of_week and first_week_of_year', missing_param: :first_week_of_year
    include_examples 'invalid combination of start_of_week and first_week_of_year', missing_param: :start_of_week
  end
end
