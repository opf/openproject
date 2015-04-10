#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module Redmine
  module Helpers
    class Diff
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TextHelper
      attr_reader :diff, :words

      def initialize(content_to, content_from)
        @words = content_to.to_s.split(/(\s+)/)
        @words = @words.select { |word| word != ' ' }
        words_from = content_from.to_s.split(/(\s+)/)
        words_from = words_from.select { |word| word != ' ' }
        @diff = words_from.diff @words
      end

      def to_html
        words = self.words.map { |word| h(word) }
        words_add = 0
        words_del = 0
        dels = 0
        del_off = 0
        diff.diffs.each do |diff|
          add_at = nil
          add_to = nil
          del_at = nil
          deleted = ''
          diff.each do |change|
            pos = change[1]
            if change[0] == '+'
              add_at = pos + dels unless add_at
              add_to = pos + dels
              words_add += 1
            else
              del_at = pos unless del_at
              deleted << ' ' + h(change[2])
              words_del  += 1
            end
          end
          if add_at
            words[add_at] = '<ins class="diffmod">'.html_safe + words[add_at]
            words[add_to] = words[add_to] + '</ins>'.html_safe
          end
          if del_at
            words.insert del_at - del_off + dels + words_add, '<del class="diffmod">'.html_safe + deleted + '</del>'.html_safe
            dels += 1
            del_off += words_del
            words_del = 0
          end
        end
        words.join(' ')
      end
    end
  end
end
