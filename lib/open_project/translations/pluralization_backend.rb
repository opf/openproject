#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

# Extends the default pluralizer I18n::Backend::Pluralization
# to be more resiliant with regards to a missing :many key in
# the l10n files of some eastern european languages
# (e.g. Russian, Hungarian, Polish)

require 'i18n/backend/pluralization'

module OpenProject
  module Translations
    module PluralizationBackend
      include ::I18n::Backend::Pluralization

      def pluralize(locale, entry, count)
        super
      rescue ::I18n::InvalidPluralizationData
        # If we have an :other key, fall back to that
        # as it will be safe to use.
        # otherwise returns nil, and results in a missing translation
        # to avoid raised exception
        if entry.key?(:other)
          entry[:other]
        end
      end
    end
  end
end
