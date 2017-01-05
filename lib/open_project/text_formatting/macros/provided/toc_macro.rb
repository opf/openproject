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
  class TocMacro < OpenProject::TextFormatting::Macros::MacroBase

    descriptor do
      prefix :opf
      id :toc
      desc <<-DESC
      Displays a table of contents.
      DESC
      param do
        id :align
        desc <<-DESC
        Aligns the toc horizontally.
        DESC
        default :left
        one_of :left, :right #, :center
        optional
      end
      param do
        id :depth
        desc <<-DESC
        Builds the toc up to the specified depth.
        DESC
        default 4
        one_of 1, 2, 3, 4, 5, 6
        optional
      end
      legacy_support
      post_process
    end

    def execute(args, fragment: nil, headings: true, **_options)
      align, depth = parse_args(args)
      do_process(fragment, align, depth) unless !headings
    end

    private

    def parse_args(args)
      align = :left
      depth = 4
      if args.instance_of?(Hash)
        align = args[:align] unless args[:align].nil?
        depth = args[:depth].to_i unless args[:depth].nil?
      else
        align = args[0].to_sym unless args.empty?
      end
      [align, depth]
    end

    def do_process(fragment, align, depth)
      parsed_headings = []
      fragment.xpath(prepare_xpath_expression(depth)).each do |node|
        entry = node.inner_text
        anchor = entry.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')
        url = full_url(anchor)
        node.name =~ /(\d)/
        level = $1
        parsed_headings << [level, url, entry.gsub(/\n/, ' ')]
        node.add_previous_sibling "<a name=\"#{anchor}\"/>"
        node.add_child "<a href=\"#{url}\" class=\"wiki-anchor\">&para;</a>"
      end
      unless parsed_headings.empty?
        view.render partial: 'wiki/macros/toc',
                    locals: { headings: parsed_headings, align: align }
      end
    end

    def prepare_xpath_expression(depth)
      levels = ''
      while depth > 0
        levels << " h#{depth}"
        depth -= 1
      end
      "*[contains('#{levels}', name())]|*//*[contains('#{levels}', name())]"
    end

    #
    # displays the current url plus an optional anchor
    #
    def full_url(anchor_name = '')
      return "##{anchor_name}" if request.nil?
      current = request.original_fullpath
      return current if anchor_name.blank?
      "#{current}##{anchor_name}"
    end

    register!
  end
end
