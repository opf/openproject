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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ITSM
  module InboundEmails
    class WorkPackageAttributes
      SUBJECT_MAX_LENGTH = 255

      def initialize(email)
        @email = email
      end

      def to_h
        { subject:, description:, journal_cause: Journal::CausedByEmail.new(sender_address: headers.from_address) }
      end

      private

      attr_reader :email

      delegate :headers, :text, to: :email

      def subject = full_subject.truncate(SUBJECT_MAX_LENGTH)

      def full_subject
        @full_subject ||= headers.subject.presence || I18n.t(:label_email_without_subject, locale: Setting.default_language)
      end

      def description
        content = [cut_subject, text].compact_blank.join("\n\n")
        return "" if content.empty?

        fence = "`" * [3, content.scan(/`+/).map(&:length).max.to_i + 1].max
        "#{fence}\n#{content}\n#{fence}"
      end

      def cut_subject
        return if full_subject.length <= SUBJECT_MAX_LENGTH

        "#{WorkPackage.human_attribute_name(:subject, locale: Setting.default_language)}: #{full_subject}"
      end
    end
  end
end
