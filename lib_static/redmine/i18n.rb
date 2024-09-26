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
  module I18n
    include ActionView::Helpers::NumberHelper

    IN_CONTEXT_TRANSLATION_CODE = :lol
    IN_CONTEXT_TRANSLATION_NAME = "In-Context Crowdin Translation".freeze

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

    def format_date(date)
      return nil unless date

      Setting.date_format.blank? ? ::I18n.l(date.to_date) : date.strftime(Setting.date_format)
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
    # @param links [Hash] Link names mapped to URLs.
    # @param target [String] optional HTML target attribute for the links.
    def link_translate(i18n_key, links: {}, locale: ::I18n.locale, target: nil)
      translation = ::I18n.t(i18n_key.to_s, locale:)
      result = translation.scan(link_regex).inject(translation) do |t, matches|
        link, text, key = matches
        href = String(links[key.to_sym])
        link_tag = content_tag(:a, text, href:, target:)

        t.sub(link, link_tag)
      end

      result.html_safe
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

    # Formats the given time as a date string according to the user's time zone and
    # optional specified format.
    #
    # @param time [Time] The time to format.
    # @param format [String, nil] The strftime format to use for the date. If nil, the default
    #   date format from `Setting.date_format` is used.
    # @return [String, nil] The formatted date string, or nil if the time is not provided.
    def format_time_as_date(time, format: nil)
      return nil unless time

      zone = User.current.time_zone
      local_date = time.in_time_zone(zone).to_date

      if format
        local_date.strftime(format)
      else
        format_date(local_date)
      end
    end

    # Formats the given time as a time string according to the user's time zone
    # and optional specified format.
    #
    # @param time [Time] The time to format.
    # @param include_date [Boolean] Whether to include the date in the formatted
    #   output. Defaults to true.
    # @param format [String] The strftime format to use for the time. Defaults
    #   to the format in `Setting.time_format`.
    # @return [String, nil] The formatted time string, or nil if the time is not
    #   provided.
    def format_time(time, include_date: true, format: Setting.time_format)
      return nil unless time

      zone = User.current.time_zone
      local = time.in_time_zone(zone)

      (include_date ? "#{format_date(local)} " : "") +
        (format.blank? ? ::I18n.l(local, format: :time) : local.strftime(format))
    end

    # Returns the offset to UTC (with utc prepended) currently active
    # in the current users time zone. DST is factored in so the offset can
    # shift over the course of the year
    def formatted_time_zone_offset
      # Doing User.current.time_zone and format that will not take heed of DST as it has no notion
      # of a current time.
      # https://github.com/rails/rails/issues/7297
      "UTC#{User.current.time_zone.now.formatted_offset}"
    end

    def day_name(day)
      ::I18n.t("date.day_names")[day % 7]
    end

    def month_name(month)
      ::I18n.t("date.month_names")[month]
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
          attr_t.merge(model_t.last || {})
        end
      end
      @cached_attribute_translations[locale]
    end
  end
end
