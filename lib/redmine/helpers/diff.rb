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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Redmine
  module Helpers
    class Diff
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::OutputSafetyHelper

      attr_reader :diff, :words

      def initialize(content_to, content_from)
        @words = content_to.to_s.split(/(\s+)/)
        @words = @words.reject { |word| word == " " }
        words_from = content_from.to_s.split(/(\s+)/)
        words_from = words_from.reject { |word| word == " " }
        @diff = words_from.diff @words
      end

      def to_html # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
        words = self.words.map { |word| h(word) }
        words_add = 0
        words_del = 0
        dels = 0
        del_off = 0
        diff.diffs.each do |diff|
          add_at = nil
          add_to = nil
          del_at = nil
          deleted_words = []
          diff.each do |change|
            pos = change[1]
            if change[0] == "+"
              add_at ||= pos + dels
              add_to = pos + dels
              words_add += 1
            else
              del_at ||= pos
              deleted_words << h(change[2])
              words_del += 1
            end
          end
          if add_at
            begin_label = content_tag(:label, WorkPackage.human_attribute_name(:begin_insertion), class: "sr-only")
            end_label = content_tag(:label, WorkPackage.human_attribute_name(:end_insertion), class: "sr-only")

            inserted = safe_join(words[add_at..add_to], " ")
            ins_tag = tag.ins(inserted, class: "diffmod")
            words[add_at] = begin_label + ins_tag + end_label
            ((add_at + 1)..add_to).each { |i| words[i] = "" }

          end
          if del_at
            begin_label = content_tag(:label, WorkPackage.human_attribute_name(:begin_deletion), class: "sr-only")
            end_label = content_tag(:label, WorkPackage.human_attribute_name(:end_deletion), class: "sr-only")
            deleted = safe_join(["", *deleted_words], " ")
            del_tag = content_tag(:del, deleted, class: "diffmod")

            words.insert del_at - del_off + dels + words_add, begin_label + del_tag + end_label
            dels += 1
            del_off += words_del
            words_del = 0
          end
        end
        words.join(" ")
      end

      def additions
        added_changes = []
        if @diff.diffs.try(:first).try(:any?)
          @diff.diffs.first.each do |change|
            if change.first == "+"
              added_changes << change.third
            end
          end
        end
        added_changes
      end
    end
  end
end
