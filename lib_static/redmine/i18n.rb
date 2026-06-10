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

# This file is to be split up into smaller files in the OpenProject namespace.
# A start has been made by splitting off OpenProject::Internationalization::Date into its own file.

module Redmine
  module I18n
    include ActionView::Helpers::NumberHelper

    IN_CONTEXT_TRANSLATION_CODE = :lol
    IN_CONTEXT_TRANSLATION_NAME = "In-Context Crowdin Translation"

    def self.included(base)
      base.extend Redmine::I18n
    end

    def self.all_languages
      @@all_languages ||= Rails.root.glob("config/locales/**/*.yml")
                               .map { |f| f.basename.to_s.split(".").first }
                               .reject! { |l| l.start_with?("js-") }
                               .uniq
                               .sort
    end

    def self.valid_languages
      all_languages & (Setting.available_languages + [Setting.default_language])
    end

    def l_or_humanize(s, options = {})
      k = :"#{options[:prefix]}#{s}"
      ::I18n.t(k, default: s.to_s.humanize)
    end

    def l_hours(hours)
      formatted = localized_float(hours)
      ::I18n.t(:label_f_hour_plural, value: formatted)
    end

    def localized_float(number, locale: ::I18n.locale, precision: 2)
      number_with_precision(number, locale:, precision:)
    rescue StandardError => e
      Rails.logger.error("Failed to localize float number #{number}: #{e}")
      ("%.2f" % hours.to_f)
    end

    # Formats the given date or datetime as a date string according to the user's time zone
    # and optional specified or system default format.
    #
    # @param date_or_time [Date|Time] The date or time object to format.
    # @param time_zone [ActiveSupport::TimeZone] Use a different time zone than the current users's.
    #   If provided, will output the time zone identifier
    # @param format [String, nil] The strftime format to use for the date. If nil, the default
    #   date format from `Setting.date_format` is used.
    def format_date(date_or_time, time_zone: nil, format: Setting.date_format)
      return nil unless date_or_time

      local =
        if time_zone
          date_or_time.in_time_zone(time_zone).to_date
        elsif date_or_time.instance_of?(Date) # Important not to use is_a? as it will match DateTime
          date_or_time
        else
          in_user_zone(date_or_time).to_date
        end

      format.present? ? ::I18n.l(local, format:) : ::I18n.l(local)
    end

    # Formats the given date pair as an HTML date range with each date
    # wrapped in a <time> element. Dates are joined by a non-breaking
    # space, an en-dash, and a non-breaking space.
    #
    # @param dates [Array<Date, nil>] A two-element array +[from, to]+;
    #   either element may be nil.
    # @return [ActiveSupport::SafeBuffer, nil] The formatted range, or nil
    #   when both dates are nil.
    def format_date_range(dates)
      return nil if dates.all?(&:nil?)

      helpers = ApplicationController.helpers
      from, to = dates.map { |date| helpers.tag.time(datetime: date.iso8601) { format_date(date) } if date }
      helpers.safe_join([from, "–", to], " ") # &ndash; and &nbsp;
    end

    ##
    # Gives a translation and inserts links into designated spots within it
    # in the style of markdown links. Instead of the actual URL only names for
    # the respective links are used in the translation.
    #
    # The method then expects a hash mapping each of those keys to actual URLs.
    #
    # For example:
    #
    #     en.yml:
    #       en:
    #         logged_out: You have been logged out. Click [here](login) to login again.
    #
    # Which would then be used like this:
    #
    #     link_translate(:logged_out, links: { login: login_url })
    #
    # @param i18n_key [String] The I18n key to translate.
    # @param i18n_args [Hash] Arguments passed to I18n.t() call
    # @param links [Hash] Link names mapped to URLs.
    # @param external [Boolean] Whether the links should be opened as external links, i.e. in a new tab (default: true)
    # @param underline [Boolean] Whether to underline links inserted into the text (default: true)
    def link_translate(i18n_key, i18n_args: {}, links: {}, external: true, underline: true, **) # rubocop:disable Metrics/AbcSize
      translation = ApplicationController.helpers.t(i18n_key.to_s, **i18n_args)
      output = ActiveSupport::SafeBuffer.new
      last_end = 0

      translation.scan(link_regex) do
        match = Regexp.last_match
        output << translation[last_end...match.begin(0)]
        output << create_link_content(match[3], match[2], external:, links:, underline:, **)
        last_end = match.end(0)
      end
      output << translation[last_end..]

      output
    end

    ##
    # Example: in `foo [bar](name) baz` matches:
    #
    #   - `[bar](name)`
    #   - `bar`
    #   - `name`
    def link_regex
      /(\[(.+?)\]\((.+?)\))/
    end

    # Formats the given time as a time string according to the user's time zone
    # and optional specified format.
    #
    # @param time [Time] The time to format.
    # @param include_date [Boolean] Whether to include the date in the formatted
    #   output. Defaults to true.
    # @param time_zone [ActiveSupport::TimeZone] Use a different time zone than the current users's.
    #   If provided, will output the time zone identifier
    # @param format [String] The strftime format to use for the time. Defaults
    #   to the format in `Setting.time_format`.
    # @return [String, nil] The formatted time string, or nil if the time is not
    #   provided.
    def format_time(time, include_date: true, time_zone: nil, format: Setting.time_format)
      return nil unless time

      local =
        if time_zone
          time.in_time_zone(time_zone)
        else
          in_user_zone(time)
        end

      parts = []
      parts << format_date(local) if include_date
      parts <<
        if format.blank?
          ::I18n.l(local, format: :time)
        else
          local.strftime(format)
        end

      parts.join(" ")
    end

    ##
    # Formats the given time as a time string according to the +user+'s time zone
    # @param time [Time] The time to format.
    # @param user [User] The user to use for the time zone. Defaults to +User.current+.
    # @return [Time] The time with the user's time zone applied.
    def in_user_zone(time, user: User.current)
      time.in_time_zone(user.time_zone)
    end

    # Returns the offset to UTC (with utc prepended) currently active
    # in the current users time zone. DST is factored in so the offset can
    # shift over the course of the year
    def formatted_time_zone_offset(user: User.current)
      # Doing User.current.time_zone and format that will not take heed of DST as it has no notion
      # of a current time.
      # https://github.com/rails/rails/issues/7297
      "UTC#{user.time_zone.now.formatted_offset}"
    end

    ##
    # Formats an ActiveSupport::TimeZone object into a user-friendly string.
    # @param time_zone [ActiveSupport::TimeZone] The time zone to format.
    # @param period [Timel] The time in which to represent the zone name.
    # Relevant for DST considerations, e.g. "CET" vs. "CEST".
    # @return [String] The formatted time zone string.
    def friendly_timezone_name(time_zone, period: Time.current)
      time_zone
        .tzinfo
        .period_for_utc(period.utc)
        .abbreviation
        .to_s
    end

    def day_name(day)
      ::I18n.t("date.day_names")[day % 7]
    end

    def month_name(month)
      ::I18n.t("date.month_names")[month]
    end

    # Localized ordinalization with optional context-specific forms.
    # This allows locales to provide different grammatical forms for the same
    # ordinal depending on usage (e.g. standalone vs. before weekday name).
    #
    # Lookup order:
    # 1. number.ordinalize.contexts.<context>.<number>
    # 2. number.ordinalize.contexts.<context>.other
    # 3. number.ordinalize.contexts.default.<number>
    # 4. number.ordinalize.contexts.default.other
    # 5. ActiveSupport fallback (e.g. 1st, 2nd, 3rd, ...)
    def ordinalize(number, context: :default)
      value = number.to_i
      context_key = :"number.ordinalize.contexts.#{context}.#{value}"
      context_other_key = :"number.ordinalize.contexts.#{context}.other"
      default_context_key = :"number.ordinalize.contexts.default.#{value}"
      default_context_other_key = :"number.ordinalize.contexts.default.other"

      ::I18n.t(
        context_key,
        default: [context_other_key, default_context_key, default_context_other_key, ActiveSupport::Inflector.ordinalize(value)],
        number: value
      )
    end

    def valid_languages
      Redmine::I18n.valid_languages
    end

    def all_languages
      Redmine::I18n.all_languages
    end

    ##
    # Returns the given language if it is valid or nil otherwise.
    def find_language(lang)
      return nil unless lang.present? && lang =~ /[a-z-]+/i

      # Direct match
      direct_match = valid_languages.detect { |l| l =~ /^#{lang}$/i }
      parent_match = valid_languages.detect { |l| l =~ /#{lang}/i }

      direct_match || parent_match
    end

    # Returns the language name in its own language for a given locale
    #
    # @param lang_code [String] the locale for the desired language, like `en`,
    #   `de`, `fil`, `zh-CN`, and so on.
    # @return [String] the language name translated in its own language
    def translate_language(lang_code)
      # rename in-context translation language name for the language select box
      if lang_code.to_sym == Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE &&
         ::I18n.locale != Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE
        [Redmine::I18n::IN_CONTEXT_TRANSLATION_NAME, lang_code.to_s]
      else
        [::I18n.t("cldr.language_name", locale: lang_code), lang_code.to_s]
      end
    end

    def set_language_if_valid(lang)
      if l = find_language(lang)
        ::I18n.locale = l
      end
    end

    def current_language
      ::I18n.locale
    end

    # Collects all translations for ActiveRecord attributes
    def all_attribute_translations(locale)
      @cached_attribute_translations ||= {}
      @cached_attribute_translations[locale] ||= begin
        general_attributes = ::I18n.t("attributes", locale:)
        ::I18n.t("activerecord.attributes",
                 locale:).inject(general_attributes) do |attr_t, model_t|
          attr_t.reverse_merge(model_t.last || {})
        end
      end
      @cached_attribute_translations[locale]
    end

    private

    def create_link_content(key, text, external:, links:, underline:, **link_arguments)
      link_reference = links.fetch(key.to_sym)
      href =
        case link_reference
        when Array
          OpenProject::Static::Links.url_for(*link_reference)
        else
          String(link_reference)
        end
      target = external ? "_blank" : nil

      # Make sure we use AC renderer here to not affect the performed? state
      # when rendering this in e.g., a before action.
      # Note: ActionController::Renderer#render does not pass blocks through to
      # ViewComponent, so slots and content must be set before rendering.
      link_arguments[:data] ||= {}
      link_arguments[:data][:allow_external_link] = true
      component = Primer::Beta::Link.new(
        **link_arguments,
        href:,
        target:,
        underline:
      )
      component.with_trailing_visual_icon(icon: :"link-external") if external
      component.with_content(text)

      ApplicationController.renderer.render(component, layout: false)
    end
  end
end
