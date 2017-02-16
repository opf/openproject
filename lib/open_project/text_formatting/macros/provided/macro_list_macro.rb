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

module OpenProject::TextFormatting::Macros::Provided
  require 'open_project/text_formatting/macros/macro_base'
  require 'open_project/text_formatting/macros/internal/macro_registry'
  require 'open_project/text_formatting/macros/internal/legacy_support_macro_descriptor'

  class MacroListMacro < OpenProject::TextFormatting::Macros::MacroBase

    descriptor do
      prefix :opf
      id 'macro-list'
      desc <<-DESC
      Displays a list of all available macros.
      DESC
      meta do
        provider 'OpenProject Foundation'
        url 'https://openproject.com'
        issues 'https://community.openproject.com'
        version 'TBD'
      end
      # param do
      #   id              :format
      #   desc <<-DESC
      #   DESC
      #   default         :plain
      #   one_of          :plain # , :interactive
      #   optional
      # end
      # param do
      #   id              :filter
      #   desc <<-DESC
      #   DESC
      #   default         nil
      #   optional
      # end
      legacy_support { id :macro_list }
    end

    def execute(args, **_options)
      unless view.respond_to?(:render)
        raise NotImplementedError, 'Macro list rendering is not supported'
      end

      format = parse_args(args)

      # TODO:coy:sort descriptors by qname
      descriptors = filter_descriptors

      view.render partial: "/wiki/macros/macro_list/#{format.to_s}/list",
                  locals: { descriptors: descriptors }
    end

    private

    # TODO:args
    #
    # format optional plain|interactive default: plain
    # filter optional ... default: nil
    def parse_args(_args)
      :plain
    end

    def filter_descriptors
      OpenProject::TextFormatting::Macros::Internal::MacroRegistry
        .instance
        .registered_macros
        .select do |descriptor|
          !descriptor.instance_of?(
            OpenProject::TextFormatting::Macros::Internal::LegacySupportMacroDescriptor
          )
        end
    end

    register!
  end
end
