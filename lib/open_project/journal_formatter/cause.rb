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

class OpenProject::JournalFormatter::Cause < JournalFormatter::Base
  include ApplicationHelper
  include WorkPackagesHelper
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::ObjectLinking

  attr_reader :cause

  def render(_key, values, options = { html: true })
    @cause = values.last
    @html = options[:html]

    "#{caused_change} #{cause_description}"
  end

  private

  def html?
    @html
  end

  def caused_change
    caused_change_text = I18n.t("journals.caused_changes.#{mapped_cause_type}",
                                default: mapped_cause_type,
                                status_name: cause["status_name"])
    if html?
      content_tag(:strong, caused_change_text)
    else
      caused_change_text
    end
  end

  def mapped_cause_type
    case cause["type"]
    when /changed_times/, "working_days_changed"
      "dates_changed"
    else
      cause["type"]
    end
  end

  def cause_description
    case cause["type"]
    when "system_update"
      system_update_message
    when "working_days_changed"
      working_days_changed_message(cause["changed_days"])
    when "status_changed"
      status_changed_message
    when "progress_mode_changed_to_status_based"
      progress_mode_changed_to_status_based_message
    else
      related_work_package_changed_message
    end
  end

  def system_update_message
    feature = cause["feature"]
    feature = "progress_calculation_adjusted" if feature == "progress_calculation_changed"

    options =
      case feature
      when "progress_calculation_adjusted_from_disabled_mode",
           "progress_calculation_adjusted"
        { href: OpenProject::Static::Links.links[:blog_article_progress_changes][:href] }
      when "totals_removed_from_childless_work_packages"
        { href: OpenProject::Static::Links.links[:release_notes_14_0_1][:href] }
      else
        {}
      end
    message = I18n.t("journals.cause_descriptions.system_update.#{feature}", **options)
    html? ? message : Sanitize.fragment(message)
  end

  def working_days_changed_message(changed_dates)
    day_changes_messages = changed_dates["working_days"].collect do |day, working|
      working_day_change_message(day.to_i, working)
    end
    date_changes_messages = changed_dates["non_working_days"].collect do |date, working|
      working_date_change_message(date, working)
    end
    I18n.t("journals.cause_descriptions.working_days_changed.changed",
           changes: (day_changes_messages + date_changes_messages).join(", "))
  end

  def working_day_change_message(day, working)
    I18n.t("journals.cause_descriptions.working_days_changed.days.#{working ? :working : :non_working}",
           day: WeekDay.find_by!(day:).name)
  end

  def working_date_change_message(date, working)
    I18n.t("journals.cause_descriptions.working_days_changed.dates.#{working ? :working : :non_working}",
           date: I18n.l(Date.parse(date)))
  end

  def status_changed_message
    cause["status_changes"]
      .sort
      .map { |change| status_change_partial_message(change) }
      .to_sentence
  end

  def status_change_partial_message(change)
    case change
    in ["default_done_ratio", [old_value, new_value]]
      I18n.t("journals.cause_descriptions.status_percent_complete_changed", old_value:, new_value:)
    in ["excluded_from_totals", [true, false]]
      I18n.t("journals.cause_descriptions.status_excluded_from_totals_set_to_false_message")
    in ["excluded_from_totals", [false, true]]
      I18n.t("journals.cause_descriptions.status_excluded_from_totals_set_to_true_message")
    end
  end

  def progress_mode_changed_to_status_based_message
    I18n.t("journals.cause_descriptions.progress_mode_changed_to_status_based")
  end

  def related_work_package_changed_message
    related_work_package = WorkPackage.includes(:project).visible(User.current).find_by(id: cause["work_package_id"])

    if related_work_package
      I18n.t(
        "journals.cause_descriptions.#{cause['type']}",
        link: html? ? link_to_work_package(related_work_package, all_link: true) : "##{related_work_package.id}"
      )

    else
      I18n.t("journals.cause_descriptions.unaccessable_work_package_changed")
    end
  end

  # we need to tell the url_helper that there is not controller to get url_options
  # so that we can later call link_to
  def controller
    nil
  end
end
