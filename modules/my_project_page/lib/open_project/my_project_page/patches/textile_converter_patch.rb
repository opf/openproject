#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::MyProjectPage::Patches
  module TextileConverterPatch
    extend ActiveSupport::Concern

    included do
      prepend(Patch)
    end

    module Patch
      def convert_my_project_page_blocks
        print ::MyProjectsOverview.name

        ::MyProjectsOverview.in_batches(of: 200) do |relation|
          relation.pluck(:id, :left, :right, :top, :hidden).each do |values|
            converted = values.drop(1).map do |block|
              block.map do |widget|
                if widget.is_a?(Array)
                  [widget[0], widget[1], convert_textile_to_markdown(widget[2])]
                else
                  widget
                end
              end
            end
            update_hash = Hash[%i[left right top hidden].zip(converted)]
            ::MyProjectsOverview.where(id: values.first).update_all(update_hash)

            print ' .'
          end
        end

        print 'done'
      end

      def converters
        super + [method(:convert_my_project_page_blocks)]
      end
    end
  end
end