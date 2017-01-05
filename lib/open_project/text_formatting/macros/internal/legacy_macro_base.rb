#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Macros::Internal
  require 'open_project/text_formatting/macros/macro_base'

  # Base class for legacy style macros
  # that we must get rid of once legacy macros have been eliminated
  class LegacyMacroBase < OpenProject::TextFormatting::Macros::MacroBase
    # include all original mixins here as we cannot know what is out
    # there in the wild... (excluding those included by MacroBase)
    include Redmine::WikiFormatting::Macros::Definitions
    include ActionView::Helpers::SanitizeHelper
    include ERB::Util # for h()
    include ActionView::Helpers::TextHelper
    include OpenProject::ObjectLinking
    # The WorkPackagesHelper is required to get access to the methods
    # 'work_package_css_classes' and 'work_package_quick_info'.
    include WorkPackagesHelper

    # calls upon execute_legacy which is the actual macro block that
    # was defined on the sub class of this by LegacyMacroFactory.
    def execute(options, args)
      obj = options[:object]
      if method(:execute_legacy).arity == 2
        Nokogiri::XML.fragment execute_legacy(obj, args)
      else
        Nokogiri::XML.fragment execute_legacy(obj, args, options)
      end
    end
  end
end
