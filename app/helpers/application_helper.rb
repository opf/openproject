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

require "forwardable"
require "cgi"

module ApplicationHelper
  include OpenProject::TextFormatting
  include OpenProject::ObjectLinking
  include OpenProject::SafeParams
  include OpPrimer::FormHelpers
  include I18n
  include ERB::Util
  include Redmine::I18n
  include HookHelper
  include IconsHelper
  include AdditionalUrlHelpers
  include OpenProject::PageHierarchyHelper

  # Return true if user is authorized for controller/action, otherwise false
  def authorize_for(controller, action, project: @project)
    User.current.allowed_in_project?({ controller:, action: }, project)
  rescue Authorization::UnknownPermissionError
    # TODO: Temporary fix until we find something better
    false
  end

  # Display a link if user is authorized
  #
  # @param [String] name Anchor text (passed to link_to)
  # @param [Hash] options Hash params. This will checked by authorize_for to see if the user is authorized
  # @param [optional, Hash] html_options Options passed to link_to
  # @param [optional, Hash] parameters_for_method_reference Extra parameters for link_to
  #
  # When a block is given, skip the name parameter
  def link_to_if_authorized(*args, &)
    name = args.shift unless block_given?
    options = args.shift || {}
    html_options = args.shift
    parameters_for_method_reference = args

    return unless authorize_for(options[:controller] || controller_path, options[:action])

    if block_given?
      link_to(options, html_options, *parameters_for_method_reference, &)
    else
      link_to(name, options, html_options, *parameters_for_method_reference)
    end
  end

  def required_field_name(name = "")
    safe_join [name, " ", content_tag("span", "*", class: "required")]
  end

  def li_unless_nil(link, options = {})
    content_tag(:li, link, options) if link
  end

  # Show a sorted linkified (if active) comma-joined list of users
  def list_users(users, options = {})
    users.sort.map { |u| link_to_user(u, options) }.join(", ")
  end

  # returns a class name based on the user's status
  def user_status_class(user)
    "status_" + user.status
  end

  def user_status_i18n(user)
    t "status_#{user.status}"
  end

  def delete_link(url, options = {})
    options = {
      data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
      class: "icon icon-delete"
    }.merge(options)

    link_to I18n.t(:button_delete), url, options
  end

  def format_activity_day(date)
    date == User.current.today ? I18n.t(:label_today).titleize : format_date(date)
  end

  def due_date_distance_in_words(date)
    if date
      label = date < Date.today ? :label_roadmap_overdue : :label_roadmap_due_in
      I18n.t(label, value: distance_of_date_in_words(Date.today, date))
    end
  end

  # Yields the given block for each project with its level in the tree
  #
  # Wrapper for Project#project_tree
  def project_tree(projects, &)
    Project.project_tree(projects, &)
  end

  def principals_check_box_tags(name, principals)
    labeled_check_box_tags(name, principals,
                           title: :user_status_i18n,
                           class: :user_status_class)
  end

  def labeled_check_box_tags(name, collection, options = {}) # rubocop:disable Metrics/AbcSize
    fields = collection.sort.map do |object|
      id = name.gsub(/[\[\]]+/, "_") + object.id.to_s

      object_options = options.inject({}) do |h, (k, v)|
        h[k] = v.is_a?(Symbol) ? send(v, object) : v
        h
      end

      object_options[:class] = Array(object_options[:class]) + %w(form--label-with-check-box)

      content_tag :div, class: "form--field" do
        label_tag(id, object, object_options) do
          styled_check_box_tag(name, object.id, false, id:) + object.to_s
        end
      end
    end

    safe_join(fields)
  end

  def authoring(created, author, options = {})
    label = options[:label] || :label_added_time_by
    # Ensure we pass inputs here to html_escape
    # which will respect html_safe?
    author = ERB::Util.html_escape link_to_user(author)
    age = ERB::Util.html_escape time_tag(created)

    # OG: html_safe is used here with explicitly escaped inputs except for the translation file
    I18n.t(label, author:, age:).html_safe
  end

  def authoring_at(creation_date, author)
    return if author.nil?

    author = ERB::Util.html_escape link_to_user(author)
    date = ERB::Util.html_escape creation_date

    # OG: html_safe is used here to avoid having to change this reusable key
    I18n.t(:label_added_by_on, author:, date:).html_safe
  end

  def time_tag(time)
    text = distance_of_time_in_words(Time.now, time)
    if @project&.module_enabled?("activity") # rubocop:disable Rails/HelperInstanceVariable
      link_to(text, { controller: "/activities",
                      action: "index",
                      project_id: @project, # rubocop:disable Rails/HelperInstanceVariable
                      from: time.to_date },
              title: format_time(time))
    else
      datetime = time.acts_like?(:time) ? time.xmlschema : time.iso8601
      content_tag(:time,
                  text,
                  datetime:,
                  title: format_time(time),
                  class: "timestamp")
    end
  end

  def syntax_highlight(name, content)
    highlighted = OpenProject::SyntaxHighlighting.highlight_by_filename(content, name)
    highlighted.each_line do |line|
      yield highlighted.html_safe? ? line.html_safe : line
    end
  end

  # Backward compatibility helper for secure_headers gem migration
  # Rails built-in CSP equivalent of nonced_javascript_tag
  def nonced_javascript_tag(**, &)
    javascript_tag(nonce: true, **, &)
  end

  def to_path_param(path)
    path.to_s
  end

  def other_formats_links(&)
    formats = capture(Redmine::Views::OtherFormatsBuilder.new(self), &)
    unless formats.nil? || formats.strip.empty?
      content_tag "p", class: "other-formats" do
        concat I18n.t(:label_export_to)
        concat formats
      end
    end
  end

  # Returns the theme, controller name, and action as css classes for the
  # HTML body.
  def body_css_classes
    css = ["theme-#{OpenProject::CustomStyles::Design.identifier}"]

    if controller_path && action_name
      css << "controller-#{controller_path}"
      css << "action-#{action_name}"
    end

    if EnterpriseToken.hide_banners?
      css << "ee-banners-hidden"
    end

    css << "env-#{Rails.env}"

    # Add browser specific classes to aid css fixes
    css += browser_specific_classes

    css.join(" ")
  end

  def accesskey(s)
    OpenProject::AccessKeys.key_for s
  end

  # Same as Rails' simple_format helper without using paragraphs
  def simple_format_without_paragraph(text)
    text.to_s.html_safe_gsub(/\r\n?/, "\n")
        .then { it.html_safe_gsub(/\n\n+/, "<br /><br />") }
        .then { it.html_safe_gsub(/([^\n]\n)(?=[^\n])/, '\1<br />') }
  end

  def lang_options_for_select(blank = true)
    options = valid_languages.map { |lang| [*translate_language(lang), { lang: }] }
    options.sort_by!(&:first)

    if blank && valid_languages.to_set == all_languages.to_set
      options.unshift([I18n.t(:label_auto_option), ""])
    end

    options
  end

  def all_lang_options_for_select
    all_languages
      .map { |lang| translate_language(lang) }
      .sort_by(&:first)
  end

  def blank_select_option
    content_tag(:option,
                "--- #{t(:actionview_instancetag_blank_option)} ---",
                disabled: true)
  end

  def theme_options_for_select
    [
      [I18n.t("themes.light"), "light"],
      [I18n.t("themes.dark"), "dark"],
      [I18n.t("themes.sync_with_os"), "sync_with_os"]
    ]
  end

  def comment_sort_order_options
    [[I18n.t("activities.work_packages.activity_tab.label_sort_asc"), "asc"],
     [I18n.t("activities.work_packages.activity_tab.label_sort_desc"), "desc"]]
  end

  def body_data_attributes(local_assigns)
    {
      controller: ["application auto-theme-switcher hover-card-trigger beforeunload external-links highlight-target-element",
                   stimulus_body_controller].compact.join(" "),
      relative_url_root: root_path,
      overflowing_identifier: ".__overflowing_body",
      external_links_enabled_value: Setting.capture_external_links?,
      rendered_at: Time.zone.now.iso8601,
      turbo: local_assigns[:turbo_opt_out] ? "false" : nil
    }.merge(user_theme_data_attributes)
     .compact
  end

  def user_theme_data_attributes
    pref = User.current.pref
    theme = pref.theme

    theme_options = {
      auto_theme_switcher_theme_value: theme,
      auto_theme_switcher_desktop_light_high_contrast_logo_class: "op-logo--link_high_contrast",
      auto_theme_switcher_mobile_white_logo_class: "op-logo--icon_white"
    }

    if pref.sync_with_os_theme?
      theme_options[:auto_theme_switcher_force_light_contrast_value] = pref.force_light_theme_contrast?
      theme_options[:auto_theme_switcher_force_dark_contrast_value] = pref.force_dark_theme_contrast?
    else
      theme_options[:color_mode] = theme
      theme_options[:"#{theme}_theme"] = theme
      theme_options[:auto_theme_switcher_increase_contrast_value] = pref.increase_theme_contrast?
    end

    theme_options
  end

  def labelled_tabular_form_for(record, options = {}, &)
    options.reverse_merge!(builder: TabularFormBuilder, html: {})
    options[:html][:class] = "form" unless options[:html].has_key?(:class)
    form_for(record, options, &)
  end

  def labelled_tabular_form_with(model: false, scope: nil, url: nil, format: nil, **options, &)
    options.reverse_merge!(builder: TabularFormBuilder, html: {})
    options[:html][:class] = "form" unless options[:html].has_key?(:class)
    form_with(model:, scope:, url:, format:, **options, &)
  end

  def back_url_hidden_field_tag(use_referer: true)
    back_url = params[:back_url] || (use_referer ? request.env["HTTP_REFERER"] : nil)
    back_url = CGI.unescape(back_url.to_s)
    hidden_field_tag("back_url", CGI.escape(back_url), id: nil) if back_url.present?
  end

  def back_url_to_current_page
    params[:back_url].presence&.to_s
  end

  def check_all_links(form_id = nil, &)
    render(OpenProject::Common::CheckAllComponent.new(checkable_id: form_id), &)
  end

  def current_layout
    controller.send :_layout, ["html"]
  end

  # Generates the HTML for a progress bar
  # Params:
  # * pcts:
  #   * a number indicating the percentage done
  #   * or an array of two numbers -> [percentage_closed, percentage_done]
  #     where percentage_closed <= percentage_done
  #     and   percentage_close + percentage_done <= 100
  # * options:
  #   A hash containing the following keys:
  #   * width: (default '100px') the css-width for the progress bar
  #   * legend: (default: '') the text displayed alond with the progress bar
  def progress_bar(pcts, options = {}) # rubocop:disable Metrics/AbcSize
    pcts = Array(pcts).map(&:round)
    closed = pcts[0]
    done = pcts[1] || 0
    width = options[:width] || "100px;"
    legend = options[:legend] || ""
    total_progress = options[:hide_total_progress] ? "" : t(:total_progress)
    percent_sign = options[:hide_percent_sign] ? "" : "%"

    content_tag :span do
      progress = content_tag :span, class: "progress-bar", style: "width: #{width}" do
        concat content_tag(:span, "", class: "inner-progress closed", style: "width: #{closed}%")
        concat content_tag(:span, "", class: "inner-progress done", style: "width: #{done}%")
      end
      progress + content_tag(:span, "#{legend}#{percent_sign} #{total_progress}", class: "progress-bar-legend")
    end
  end

  def checked_image(checked = true)
    if checked
      icon_wrapper("icon-context icon-checkmark", t(:label_checked))
    end
  end

  def calendar_for(*_args)
    ActiveSupport::Deprecation.new.warn(
      "calendar_for has been removed. Please use the opce-basic-single-date-picker angular component instead",
      caller_locations
    )
  end

  def locale_first_day_of_week
    case Setting.start_of_week.to_i
    when 1
      "1" # Monday
    when 7
      "0" # Sunday
    when 6
      "6" # Saturday
    else
      # use language default (pass a blank string) and moment.js will reuse existing info
      # /frontend/src/main.ts
      ""
    end
  end

  def locale_first_week_of_year
    case Setting.first_week_of_year.to_i
    when 1
      "1" # Monday
    when 4
      "4" # Thursday
    else
      # use language default (pass a blank string) and moment.js will reuse existing info
      # /frontend/src/main.ts
      ""
    end
  end

  # To avoid FOUC (menu flickering / dark mode on logout), hide page
  # wrapper on load except in test environment.
  def initial_menu_styles
    Rails.env.test? || "display:none"
  end

  def initial_menu_classes(side_displayed, show_decoration)
    classes = "can-hide-navigation"
    classes += " nosidebar" unless side_displayed
    classes += " nomenus" unless show_decoration

    classes
  end

  # Add a HTML meta tag to control robots (web spiders)
  #
  # @param [optional, String] content the content of the ROBOTS tag.
  #   defaults to no index, follow, and no archive
  def robot_exclusion_tag(content = "NOINDEX,FOLLOW,NOARCHIVE")
    tag(:meta, name: "ROBOTS", content:)
  end

  def permitted_params
    PermittedParams.new(params, current_user)
  end

  def link_to_content_update(name, options = {}, html_options = {}, &)
    link_to(name, options, html_options.reverse_merge(target: "_top"), &)
  end

  def password_complexity_requirements
    render_password_requirements
  end

  def render_password_requirements
    evaluator = OpenProject::Passwords::Evaluator
    content_tag(:ul, class: "op-password-requirements") do
      concat password_requirement_item(evaluator.min_length_description,
                                       data: { "requirement-type": "length",
                                               "min-length": evaluator.min_length })
      evaluator.active_rules.each do |rule|
        concat password_requirement_item(I18n.t("label_password_requirement_#{rule}"),
                                         data: { "requirement-type": "rule", rule: })
      end
    end
  end

  private

  def password_requirement_item(label, data: {})
    content = safe_join(
      [
        content_tag(:span, render(Primer::Beta::Octicon.new(icon: :check)),
                    class: "op-password-requirements--item-check"),
        content_tag(:span, render(Primer::Beta::Octicon.new(icon: :x)),
                    class: "op-password-requirements--item-cross"),
        label
      ]
    )

    content_tag(:li,
                content,
                class: "op-password-requirements--item",
                data: data.merge("password-requirements-target": "requirement"))
  end
end
