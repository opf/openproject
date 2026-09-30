# frozen_string_literal: true

#-- copyright
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Use the language spoken in the evil realm of Mordor. Fortunately, it's
# only used for testing.
RSpec.shared_context "with locale for testing" do
  let(:enforce_available_locales) { I18n.config.enforce_available_locales }
  let(:translations) { {} }

  before do
    I18n.config.enforce_available_locales = !enforce_available_locales
    I18n.backend.store_translations(:mo, translations)
    I18n.locale = :mo
  end

  after do
    I18n.locale = I18n.default_locale
    I18n.backend.translations.delete(:mo)
    I18n.config.enforce_available_locales = enforce_available_locales
  end
end
