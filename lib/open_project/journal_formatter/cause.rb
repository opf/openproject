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
    when "total_percent_complete_mode_changed_to_work_weighted_average"
      total_percent_complete_mode_changed_to_work_weighted_average_message
    when "total_percent_complete_mode_changed_to_simple_average"
      total_percent_complete_mode_changed_to_simple_average_message
    when "import"
      import_message
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
        { href: OpenProject::Static::Links.url_for(:blog_article_progress_changes) }
      when "totals_removed_from_childless_work_packages"
        { href: OpenProject::Static::Links.url_for(:release_notes_14_0_1) }
      when "sprint_migration"
        { version_name: ERB::Util.html_escape(cause["version_name"]) }
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

  def total_percent_complete_mode_changed_to_work_weighted_average_message
    I18n.t("journals.cause_descriptions.total_percent_complete_mode_changed_to_work_weighted_average")
  end

  def total_percent_complete_mode_changed_to_simple_average_message
    I18n.t("journals.cause_descriptions.total_percent_complete_mode_changed_to_simple_average")
  end

  def import_message
    entries = cause["import_history"]
    return "" if entries.blank?

    entry_messages = entries.map { |entry| import_entry_message(entry) }
    entry_messages.compact.join(html? ? "<br/><br/>" : "\n\n")
  end

  def import_entry_message(entry)
    author = h(entry["author_name"])
    items = entry["items"]

    item_messages = items&.map { |item| import_message_item(item) } || []
    [
      I18n.t("journals.cause_descriptions.import.header", author:),
      *item_messages
    ].compact.join(html? ? "<br/>" : "\n")
  end

  def import_message_item(item)
    field_label = item["field"]
    return import_message_diff_item(field_label, item) if field_label&.downcase == "description"

    from_string = h(item["fromString"])
    to_string   = h(item["toString"])
    field = html? ? content_tag(:strong, field_label) : field_label

    import_field_change_message(field, from_string, to_string)
  end

  def import_field_change_message(field, from_string, to_string)
    if from_string.present? && to_string.present?
      I18n.t("journals.cause_descriptions.import.field_changed",
             field:, old_value: from_string, new_value: to_string)
    elsif to_string.present?
      I18n.t("journals.cause_descriptions.import.field_set", field:, value: to_string)
    elsif from_string.present?
      I18n.t("journals.cause_descriptions.import.field_removed", field:)
    else
      I18n.t("journals.cause_descriptions.import.field_updated", field:)
    end
  end

  def import_message_diff_item(field_label, item)
    from_string = item["fromString"]
    to_string = item["toString"]

    field = html? ? content_tag(:strong, field_label) : field_label
    link = import_message_diff_link

    if to_string.blank?
      I18n.t("journals.cause_descriptions.import.deleted_with_diff", field:, link:)
    elsif from_string.present?
      I18n.t("journals.cause_descriptions.import.changed_with_diff", field:, link:)
    else
      I18n.t("journals.cause_descriptions.import.set_with_diff", field:, link:)
    end
  end

  def import_message_diff_link
    url_attr = {
      only_path: true,
      script_name: ::OpenProject::Configuration.rails_relative_url_root,
      controller: "/journals",
      action: "diff",
      id: @journal.id,
      field: "description"
    }

    if html?
      link_to(I18n.t(:label_details), url_attr, target: "_top", class: "diff-details")
    else
      url_for(url_attr)
    end
  end

  def related_work_package_changed_message
    related_work_package = WorkPackage.includes(:project).visible(User.current).find_by(id: cause["work_package_id"])

    if related_work_package
      I18n.t(
        "journals.cause_descriptions.#{cause['type']}",
        link: html? ? link_to_work_package(related_work_package, link_subject: true) : related_work_package.formatted_id
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
