#-- encoding: UTF-8
#
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module WorkPackagesHelper
  def work_package_breadcrumb
    full_path = ancestors_links.unshift(work_package_index_link)

    breadcrumb_paths(*full_path)
  end

  def ancestors_links
    controller.ancestors.map do |parent|
      link_to '#' + h(parent.id), work_package_path(parent.id)
    end
  end

  def work_package_index_link
    # TODO: will need to change to work_package index
    link_to(t(:label_work_package_plural), {:controller => '/issues', :action => 'index'})
  end

  # Displays a link to +work_package+ with its subject.
  # Examples:
  #
  #   link_to_work_package(package)                             # => Defect #6: This is the subject
  #   link_to_work_package(package, :all_link => true)          # => Defect #6: This is the subject (everything within the link)
  #   link_to_work_package(package, :truncate => 9)             # => Defect #6: This i...
  #   link_to_work_package(package, :subject => false)          # => Defect #6
  #   link_to_work_package(package, :type => false)             # => #6: This is the subject
  #   link_to_work_package(package, :project => true)           # => Foo - Defect #6
  #   link_to_work_package(package, :id_only => true)           # => #6
  #   link_to_work_package(package, :subject_only => true)      # => This is the subject (as link)
  def link_to_work_package(package, options = {})

    if options[:subject_only]
      options.merge!(:type => false,
                     :subject => true,
                     :id => false,
                     :all_link => true)
    elsif options[:id_only]
      options.merge!(:type => false,
                     :subject => false,
                     :id => true,
                     :all_link => true)
    else
      options.reverse_merge!(:type => true,
                             :subject => true,
                             :id => true)
    end

    parts = { :prefix => [],
              :hidden_link => [],
              :link => [],
              :suffix => [],
              :title => [] }

    # Prefix part

    parts[:prefix] << "#{package.project}" if options[:project]

    # Link part

    parts[:link] << h(options[:before_text].to_s) if options[:before_text]

    parts[:link] << h(package.kind.to_s) if options[:type]

    parts[:link] << "##{package.id}" if options[:id]

    # Hidden link part

    if package.closed?
      parts[:hidden_link] << content_tag(:span,
                                         t(:label_closed_work_packages),
                                         :class => "hidden-for-sighted")
    end

    # Suffix part

    if options[:subject]
      subject = if options[:subject]
                  subject = package.subject
                  if options[:truncate]
                    subject = truncate(subject, :length => options[:truncate])
                  end

                  subject
                end

      parts[:suffix] << subject
    end

    # title part

    parts[:title] << package.subject

    # combining

    prefix = parts[:prefix].join(" ")
    suffix = parts[:suffix].join(" ")
    link = parts[:link].join(" ").strip
    hidden_link = parts[:hidden_link].join("")
    title = parts[:title].join(" ")

    text = if options[:all_link]
             link_text = [prefix, link].reject(&:empty?).join(" - ")
             link_text = [link_text, suffix].reject(&:empty?).join(": ")
             link_text = [hidden_link, link_text].reject(&:empty?).join("")

             link_to(link_text.html_safe,
                     work_package_path(package),
                     :title => title)
           else
             link_text = [hidden_link, link].reject(&:empty?).join("")

             html_link = link_to(link_text.html_safe,
                                 work_package_path(package),
                                 :title => title)

             [[prefix, html_link].reject(&:empty?).join(" - "),
              suffix].reject(&:empty?).join(": ")
            end.html_safe
  end

  def work_package_quick_info(work_package)
    changed_dates = {}

    journals = work_package.journals.where(["created_at >= ?", Date.today.to_time - 7.day])
                                    .order("created_at desc")

    journals.each do |journal|
      break if changed_dates["start_date"] && changed_dates["due_date"]

      ["start_date", "due_date"].each do |date|
        if changed_dates[date].nil? &&
           journal.changed_data[date] &&
           journal.changed_data[date].first
              changed_dates[date] = " (<del>#{journal.changed_data[date].first}</del>)".html_safe
        end
      end
    end

    link = link_to_work_package(work_package)
    link += " #{work_package.start_date.nil? ? "[?]" : work_package.start_date.to_s}"
    link += changed_dates["start_date"]
    link += " – #{work_package.due_date.nil? ? "[?]" : work_package.due_date.to_s}"
    link += changed_dates["due_date"]

    link
  end

  def work_package_quick_info_with_description(work_package, lines = 3)
    description_lines = work_package.description.to_s.lines.to_a[0,lines]

    if description_lines[lines-1] && work_package.description.to_s.lines.to_a.size > lines
      description_lines[lines-1].strip!

      while !description_lines[lines-1].end_with?("...") do
        description_lines[lines-1] = description_lines[lines-1] + "."
      end
    end

    description = if work_package.description.blank?
                    "-"
                  else
                    textilizable(description_lines.join(""))
                  end

    link = work_package_quick_info(work_package)

    link += content_tag(:div, :class => 'indent quick_info attributes') do

      responsible = if work_package.responsible_id.present?
                      "<span class='label'>#{WorkPackage.human_attribute_name(:responsible)}:</span> " +
                      "#{work_package.responsible.name}"
                    end

      assignee = if work_package.assigned_to_id.present?
                   "<span class='label'>#{WorkPackage.human_attribute_name(:assigned_to)}:</span> " +
                   "#{work_package.assigned_to.name}"
                 end

      [responsible, assignee].compact.join("<br>").html_safe
    end

    link += content_tag(:div, description, :class => 'indent quick_info description')

    link
  end

  def work_package_list(work_packages, &block)
    ancestors = []
    work_packages.each do |work_package|
      while (ancestors.any? && !work_package.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield work_package, ancestors.size
      ancestors << work_package unless work_package.leaf?
    end
  end

  def send_notification_option
    content_tag(:label,
                l(:label_notify_member_plural),
                  :for => 'send_notification') +
    hidden_field_tag('send_notification', '0', :id => nil) +
    check_box_tag('send_notification', '1', true)
  end

  def render_work_package_tree_row(work_package, level, relation)
    css_classes = ["work-package"]
    css_classes << "work-package-#{work_package.id}"
    css_classes << "idnt" << "idnt-#{level}" if level > 0

    if relation == "root"
      issue_text = link_to("#{work_package.to_s}",
                             'javascript:void(0)',
                             :style => "color:inherit; font-weight: bold; text-decoration:none; cursor:default;")
    else
      title = []

      if relation == "parent"
        title << content_tag(:span, l(:description_parent_work_package), :class => "hidden-for-sighted")
      elsif relation == "child"
        title << content_tag(:span, l(:description_sub_work_package), :class => "hidden-for-sighted")
      end

      issue_text = link_to(work_package.to_s.html_safe, work_package_path(work_package))
    end

    content_tag :tr, :class => css_classes.join(' ') do
      concat content_tag :td, check_box_tag("ids[]", work_package.id, false, :id => nil), :class => 'checkbox'
      concat content_tag :td, issue_text, :class => 'subject'
      concat content_tag :td, h(work_package.status)
      concat content_tag :td, link_to_user(work_package.assigned_to)
      concat content_tag :td, link_to_version(work_package.fixed_version)
    end
  end

  # Returns a string of css classes that apply to the issue
  def work_package_css_classes(work_package)
    #TODO: remove issue once css is cleaned of it
    s = "issue work_package".html_safe
    s << " status-#{work_package.status.position}" if work_package.status
    s << " priority-#{work_package.priority.position}" if work_package.priority
    s << ' closed' if work_package.closed?
    s << ' overdue' if work_package.overdue?
    s << ' child' if work_package.child?
    s << ' parent' unless work_package.leaf?
    s << ' created-by-me' if User.current.logged? && work_package.author_id == User.current.id
    s << ' assigned-to-me' if User.current.logged? && work_package.assigned_to_id == User.current.id
    s
  end

  WorkPackageAttribute = Struct.new(:attribute, :field)

  def work_package_form_all_middle_attributes(form, work_package, locals = {})
    [
      work_package_form_status_attribute(form, work_package, locals),
      work_package_form_priority_attribute(form, work_package, locals),
      work_package_form_assignee_attribute(form, work_package, locals),
      work_package_form_responsible_attribute(form, work_package, locals),
      work_package_form_issue_category_attribute(form, work_package, locals),
      work_package_form_assignable_versions_attribute(form, work_package, locals),
      work_package_form_start_date_attribute(form, work_package, locals),
      work_package_form_due_date_attribute(form, work_package, locals),
      work_package_form_estimated_hours_attribute(form, work_package, locals),
      work_package_form_done_ratio_attribute(form, work_package, locals),
      work_package_form_custom_values_attribute(form, work_package, locals)
    ].flatten.compact
  end

  def work_package_form_minimal_middle_attributes(form, work_package, locals = {})
    [
      work_package_form_status_attribute(form, work_package, locals),
      work_package_form_assignee_attribute(form, work_package, locals),
      work_package_form_assignable_versions_attribute(form, work_package, locals),
      work_package_form_done_ratio_attribute(form, work_package, locals),
    ].flatten.compact
  end

  def work_package_form_top_attributes(form, work_package, locals = {})
    [
      work_package_form_type_attribute(form, work_package, locals),
      work_package_form_subject_attribute(form, work_package, locals),
      work_package_form_parent_attribute(form, work_package, locals),
      work_package_form_description_attribute(form, work_package, locals)
    ].compact
  end

  def work_package_show_attributes(work_package)
    [
      work_package_show_status_attribute(work_package),
      work_package_show_start_date_attribute(work_package),
      work_package_show_priority_attribute(work_package),
      work_package_show_due_date_attribute(work_package),
      work_package_show_assigned_to_attribute(work_package),
      work_package_show_progress_attribute(work_package),
      work_package_show_responsible_attribute(work_package),
      work_package_show_category_attribute(work_package),
      work_package_show_spent_time_attribute(work_package),
      work_package_show_fixed_version_attribute(work_package),
      work_package_show_estimated_hours_attribute(work_package)
    ].compact
  end

  def work_package_show_table_row(attribute, klass = nil, &block)
    klass = attribute.to_s.dasherize if klass.nil?

    content = content_tag(:th, :class => klass) { "#{Issue.human_attribute_name(attribute)}:" }
    content << content_tag(:td, :class => klass, &block)

    WorkPackageAttribute.new(attribute, content)
  end

  def work_package_show_status_attribute(work_package)
    work_package_show_table_row(:status) do
      work_package.status ?
        work_package.status.name :
        "-"
    end
  end

  def work_package_show_start_date_attribute(work_package)
    work_package_show_table_row(:start_date, 'start-date') do
      work_package.start_date ?
        format_date(work_package.start_date) :
        "-"
    end
  end

  def work_package_show_priority_attribute(work_package)
    work_package_show_table_row(:priority) do
      work_package.priority ?
        work_package.priority.name :
        "-"
    end
  end

  def work_package_show_due_date_attribute(work_package)
    work_package_show_table_row(:due_date) do
      work_package.due_date ?
        format_date(work_package.due_date) :
        "-"
    end
  end

  def work_package_show_assigned_to_attribute(work_package)
    work_package_show_table_row(:assigned_to) do
      content = avatar(work_package.assigned_to, :size => "14").html_safe
      content << (work_package.assigned_to ? link_to_user(work_package.assigned_to) : "-")
      content
    end
  end

  def work_package_show_responsible_attribute(work_package)
    work_package_show_table_row(:responsible) do
      content = avatar(work_package.responsible, :size => "14").html_safe
      content << (work_package.responsible ? link_to_user(work_package.responsible) : "-")
      content
    end
  end

  def work_package_show_progress_attribute(work_package)
    work_package_show_table_row(:progress, 'done-ratio') do
      progress_bar work_package.done_ratio, :width => '80px', :legend => work_package.done_ratio.to_s
    end
  end

  def work_package_show_category_attribute(work_package)
    work_package_show_table_row(:category) do
      work_package.category ?
        work_package.category.name :
        '-'
    end
  end

  def work_package_show_spent_time_attribute(work_package)
    work_package_show_table_row(:spent_time) do
      work_package.spent_hours > 0 ?
        link_to(l_hours(work_package.spent_hours), issue_time_entries_path(work_package)) :
        "-"
    end
  end

  def work_package_show_fixed_version_attribute(work_package)
    work_package_show_table_row(:fixed_version) do
      work_package.fixed_version ?
        link_to_version(work_package.fixed_version) :
        "-"
    end
  end

  def work_package_show_estimated_hours_attribute(work_package)
    work_package_show_table_row(:estimated_hours) do
      work_package.estimated_hours ?
        l_hours(work_package.estimated_hours) :
        "-"
    end
  end

  def work_package_form_type_attribute(form, work_package, locals = {})
    selectable_types = locals[:project].types.collect {|t| [((t.is_standard) ? '' : t.name), t.id]}

    field = form.select :type_id, selectable_types, :required => true

    url = work_package.new_record? ?
           new_type_project_work_packages_path(locals[:project]) :
           new_type_work_package_path(work_package)

    field += observe_field :work_package_type_id, :url => url,
                                                  :update => :attributes,
                                                  :method => :get,
                                                  :with => "Form.serialize('work_package-form')"

    WorkPackageAttribute.new(:type, field)
  end

  def work_package_form_subject_attribute(form, work_package, locals = {})
    WorkPackageAttribute.new :subject, form.text_field(:subject, :size => 80, :required => true)
  end

  def work_package_form_parent_attribute(form, work_package, locals = {})
    if User.current.allowed_to?(:manage_subtasks, locals[:project])
      field = if work_package.is_a?(Issue)
                form.text_field :parent_id, :size => 10, :title => l(:description_autocomplete)
              else
                form.text_field :parent_id, :size => 10, :title => l(:description_autocomplete)
              end

      field += '<div id="parent_issue_candidates" class="autocomplete"></div>'.html_safe
      field += javascript_tag "observeWorkPackageParentField('#{issues_auto_complete_path(:id => work_package, :project_id => locals[:project], :escape => false) }')"

      WorkPackageAttribute.new(:parent_issue, field)
    end
  end

  def work_package_form_description_attribute(form, work_package, locals = {})
    field = form.text_area :description,
                           :cols => 60,
                           :rows => (work_package.description.blank? ? 10 : [[10, work_package.description.length / 50].max, 100].min),
                           :accesskey => accesskey(:edit),
                           :class => 'wiki-edit'

    WorkPackageAttribute.new(:description, field)
  end

  def work_package_form_status_attribute(form, work_package, locals = {})
    new_statuses = work_package.new_statuses_allowed_to(locals[:user], true)

    field = if new_statuses.any?
              form.select(:status_id, (new_statuses.map {|p| [p.name, p.id]}), :required => true)
            elsif work_package.status
              form.label(:status) + work_package.status.name
            else
              form.label(:status) + "-"
            end

    WorkPackageAttribute.new(:status, field)
  end

  def work_package_form_priority_attribute(form, work_package, locals = {})
    WorkPackageAttribute.new(:priority,
                             form.select(:priority_id, (locals[:priorities].map {|p| [p.name, p.id]}), {:required => true}, :disabled => attrib_disabled?(work_package, 'priority_id')))
  end

  def work_package_form_assignee_attribute(form, work_package, locals = {})
    WorkPackageAttribute.new(:assignee,
                             form.select(:assigned_to_id, (work_package.assignable_users.map {|m| [m.name, m.id]}), :include_blank => true))
  end

  def work_package_form_responsible_attribute(form, work_package, locals = {})
    WorkPackageAttribute.new(:assignee,
                             form.select(:responsible_id, options_for_responsible(locals[:project]), :include_blank => true))
  end

  def work_package_form_issue_category_attribute(form, work_package, locals = {})
    unless locals[:project].issue_categories.empty?
      field = form.select(:category_id,
                          (locals[:project].issue_categories.collect {|c| [c.name, c.id]}),
                          :include_blank => true)

      field += prompt_to_remote(image_tag('plus.png', :style => 'vertical-align: middle;'),
                                         t(:label_work_package_category_new),
                                         'category[name]',
                                         project_issue_categories_path(locals[:project]),
                                         :title => t(:label_work_package_category_new)) if authorize_for('issue_categories', 'new')

      WorkPackageAttribute.new(:category, field)
    end
  end

  def work_package_form_assignable_versions_attribute(form, work_package, locals = {})
    unless work_package.assignable_versions.empty?
      field = form.select(:fixed_version_id,
                          version_options_for_select(work_package.assignable_versions, work_package.fixed_version),
                          :include_blank => true)
      field += prompt_to_remote(image_tag('plus.png', :style => 'vertical-align: middle;'),
                             l(:label_version_new),
                             'version[name]',
                             new_project_version_path(locals[:project]),
                             :title => l(:label_version_new)) if authorize_for('versions', 'new')

      WorkPackageAttribute.new(:fixed_version, field)
    end
  end

  def work_package_form_start_date_attribute(form, work_package, locals = {})
    start_date_field = form.text_field :start_date, :size => 10, :disabled => attrib_disabled?(work_package, 'start_date')
    start_date_field += calendar_for("#{form.object_name}_start_date") unless attrib_disabled?(work_package, 'start_date')

    WorkPackageAttribute.new(:start_date, start_date_field)
  end

  def work_package_form_due_date_attribute(form, work_package, locals = {})
    due_date_field = form.text_field :due_date, :size => 10, :disabled => attrib_disabled?(work_package, 'due_date')
    due_date_field += calendar_for("#{form.object_name}_due_date") unless attrib_disabled?(work_package, 'due_date')

    WorkPackageAttribute.new(:due_date, due_date_field)
  end

  def work_package_form_estimated_hours_attribute(form, work_package, locals = {})
    field = form.text_field :estimated_hours,
                            :size => 3,
                            :disabled => attrib_disabled?(work_package, 'estimated_hours'),
                            :value => number_with_precision(work_package.estimated_hours, :precision => 2)

    field += TimeEntry.human_attribute_name(:hours)

    WorkPackageAttribute.new(:estimated_hours, field)
  end

  def work_package_form_done_ratio_attribute(form, work_package, locals = {})
    if !attrib_disabled?(work_package, 'done_ratio') && Issue.use_field_for_done_ratio?

      field = form.select(:done_ratio, ((0..10).to_a.collect {|r| ["#{r*10} %", r*10] }))

      WorkPackageAttribute.new(:done_ratio, field)
    end
  end

  def work_package_form_custom_values_attribute(form, work_package, locals = {})
    work_package.custom_field_values.map do |value|
      field = custom_field_tag_with_label :work_package, value

      WorkPackageAttribute.new(:"work_package_#{value.id}", field)
    end
  end
end
