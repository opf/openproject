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

require 'open_project/plugins'

module OpenProject::Translations
  class Engine < ::Rails::Engine
    engine_name :openproject_translations

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-translations',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 4.0.0'

    # load custom translation rules, as stored in config/locales/plurals.rb
    # to be aware of e.g. Japanese not having a plural from for nouns
    initializer 'translation.pluralization.rules' do
      require 'open_project/translations/pluralization_backend'
      I18n::Backend::Simple.send(:include, OpenProject::Translations::PluralizationBackend)
    end
  end
end
