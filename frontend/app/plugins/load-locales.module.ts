// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

export class LoadLocales {
  public static I18n:op.I18n;

  public static files(localeFiles) {
    localeFiles.keys().forEach(function(localeFile) {
      var locale_matches = localeFile.match(/js-((\w{2})(-\w{2})?)\.yml/);
      var locale_with_country = locale_matches[1];
      var locale_without_country = locale_matches[2];

      var localizations = localeFiles(localeFile)[locale_without_country];
      var locale = locale_without_country;

      // Some locales e.g. es-ES have a language postfix but within the yml files
      // that postfix is lacking.
      if (!localizations) {
        localizations = localeFiles(localeFile)[locale_with_country];
        locale = locale_with_country;
      }

      this.I18n.addTranslations(locale, localizations);
    });
  }
}
