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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Patches
    ##
    # Crowdin currently breaks some of our pluralized strings
    # in locales other than the english source.
    #
    # Strings are being downloaded with an empty string as value despite
    # showing up correctly in their UI.
    #
    # This results in the fallback not properly working as it's not checking
    # for empty strings.
    #
    # This patch removes empty string values from the loaded YML before they
    # are being processed by fallbacks. With it, english fallbacks can be used automatically.
    # https://community.openproject.com/wp/36304
    module I18nRejectEmptyString
      def load_yml(filename)
        hash, frozen = super
        [replace_empty_strings(hash), frozen]
      end

      def replace_empty_strings(hash)
        hash.deep_transform_values do |value|
          if value == ""
            nil
          else
            value
          end
        end
      end
    end
  end
end

OpenProject::Patches.patch_gem_version "i18n", "1.14.5" do
  I18n.backend.singleton_class.prepend OpenProject::Patches::I18nRejectEmptyString
end
