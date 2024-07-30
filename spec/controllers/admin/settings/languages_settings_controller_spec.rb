# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Admin::Settings::LanguagesSettingsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  require_admin_and_render_template("languages_settings")

  describe "PATCH #update" do
    subject { patch "update", params: }

    let(:available_languages) { %w[en fr de] }
    let(:base_settings) do
      { available_languages: }
    end
    let(:params) { { settings: } }

    context "with valid params" do
      let(:settings) { base_settings }

      it "succeeds" do
        subject

        expect(response).to redirect_to action: :show
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
      end

      it "sets language of users having a non-available language to the default language",
         with_settings: { available_languages: %w[en de ja], default_language: "de" } do
        user_de = create(:user, language: "de")
        user_en = create(:user, language: "en")
        user_foo = create(:user, language: "foo")
        user_fr = create(:user, language: "fr")
        user_ja = create(:user, language: "ja")

        subject

        expect(user_de.reload.language).to eq("de")
        expect(user_en.reload.language).to eq("en")
        expect(user_foo.reload.language).to eq("de")
        expect(user_fr.reload.language).to eq("de")
        expect(user_ja.reload.language).to eq("ja")
      end
    end
  end
end
