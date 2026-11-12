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

module RootSeederTestHelpers
  def with_edition(edition)
    RSpec::Mocks.with_temporary_scope do
      with_config(edition:)
      yield
    end
  end

  # The example needs to have the :settings_reset metadata to have
  # `reset(:default_language)` working.
  def with_locale_env(locale, env_var_name: "OPENPROJECT_SEED_LOCALE", &)
    with_env(env_var_name => locale) do
      reset(:default_language) # Settings are a pain to reset
      yield
    ensure
      reset(:default_language)
    end
  end
end
