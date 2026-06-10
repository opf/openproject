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

module WorkPackagesHelper
  include AccessibilityHelper
  extend DeprecatedAlias

  # Displays a link to +work_package+ with its subject.
  # Examples:
  #
  #   link_to_work_package(package)                            # => Defect <id>: This is the subject
  #   link_to_work_package(package, link_subject: true)        # => Defect <id>: This is the subject (everything within the link)
  #   link_to_work_package(package, display_project: true)     # => Foo - Defect <id>: This is the subject
  def link_to_work_package(work_package, display_project: false, link_subject: false) # rubocop:disable Metrics/AbcSize
    output = ActiveSupport::SafeBuffer.new
    output << "#{work_package.project} - " if display_project && work_package.project_id

    link = link_to(work_package_path(work_package),
                   title: work_package.subject,
                   class: link_to_work_package_css_classes(work_package)) do
      link_parts = []
      link_parts << work_package.type.to_s if work_package.type_id
      link_parts << "#{work_package.formatted_id}:"
      link_parts << content_tag(:span, I18n.t(:label_closed_work_packages), class: "sr-only") if work_package.closed?
      link_parts << work_package.subject if link_subject

      safe_join(link_parts, " ")
    end

    output << link
    output << " #{work_package.subject}" unless link_subject
    output
  end

  def work_package_list(work_packages, &)
    ancestors = []
    work_packages.each do |work_package|
      while ancestors.any? && !work_package.is_descendant_of?(ancestors.last)
        ancestors.pop
      end
      yield work_package, ancestors.size
      ancestors << work_package unless work_package.leaf?
    end
  end

  def work_package_dates_icon(work_package)
    work_package.schedule_manually ? :pin : "op-auto-date"
  end

  def work_package_formatted_dates(work_package)
    start_date = work_package.start_date ? format_date(work_package.start_date) : nil
    due_date = work_package.due_date ? format_date(work_package.due_date) : nil

    # If both dates are missing, return just one dash
    return "-" if start_date.nil? && due_date.nil?

    return start_date if start_date == due_date

    # Return the formatted date range (start_date - due_date)
    "#{start_date} - #{due_date}"
  end

  def send_notification_option(checked: false)
    content_tag(:label, for: "send_notification", class: "form--label-with-check-box") do
      (content_tag "span", class: "form--check-box-container" do
        boxes = hidden_field_tag("send_notification", "0", id: nil)

        boxes += check_box_tag("send_notification",
                               "1",
                               checked,
                               class: "form--check-box")
        boxes
      end) + I18n.t("notifications.send_notifications")
    end
  end

  def back_url_is_wp_show?
    route = OpenProject::StaticRouting.recognize_route(params[:back_url] || request.env["HTTP_REFERER"])
    return false if route.nil?

    route[:controller] == "work_packages" && route[:action] == "index" && route[:state]&.match?(/^\d+/)
  end

  def last_work_package_note(work_package)
    note_journals = work_package.journals.internal_visible.select(&:notes?)
    return t(:text_no_notes) if note_journals.empty?

    note_journals.last.notes
  end

  def work_packages_columns_options
    @work_packages_columns_options ||= Query
      .new
      .displayable_columns
      .sort_by(&:caption)
      .map { |column| { name: column.caption, id: column.name.to_s } }
  end

  def selected_work_packages_columns_options
    Setting[:work_package_list_default_columns]
      .filter_map { |column| work_packages_columns_options.find { |c| c[:id] == column } }
  end

  def protected_work_packages_columns_options
    protected_columns = %w[id subject]
    work_packages_columns_options
      .select { |column| protected_columns.include?(column[:id]) }
  end

  private

  def truncated_work_package_description(work_package, lines = 3) # rubocop:disable Metrics/AbcSize
    description_lines = work_package.description.to_s.lines.to_a[0, lines]

    if description_lines[lines - 1] && work_package.description.to_s.lines.to_a.size > lines
      description_lines[lines - 1].strip!

      while !description_lines[lines - 1].end_with?("...")
        description_lines[lines - 1] = description_lines[lines - 1] + "."
      end
    end

    if work_package.description.blank?
      empty_element_tag
    else
      ::OpenProject::TextFormatting::Renderer.format_text(
        description_lines.join,
        object: work_package,
        attribute: :description,
        no_nesting: true
      )
    end
  end

  def link_to_work_package_css_classes(package)
    classes = ["work_package"]
    classes << "closed" if package.closed?

    classes
  end
end
