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

module WorkPackagesHelper
  include AccessibilityHelper
  extend DeprecatedAlias

  def work_package_breadcrumb
    full_path = if !@project.nil?
                  link_to(I18n.t(:label_work_package_plural), project_path(@project, jump: current_menu_item))
                else
                  ancestors_links.unshift(work_package_index_link)
                end

    breadcrumb_paths(*full_path)
  end

  def ancestors_links
    controller.ancestors.map do |parent|
      link_to '#' + h(parent.id), work_package_path(parent.id)
    end
  end

  def work_package_index_link
    # TODO: will need to change to work_package index
    link_to(I18n.t(:label_work_package_plural), controller: :work_packages, action: :index)
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
  #   link_to_work_package(package, :status => true)            # => #6 New (if #id => true)
  def link_to_work_package(package, options = {})
    if options[:subject_only]
      options.merge!(type: false,
                     subject: true,
                     id: false,
                     all_link: true)
    elsif options[:id_only]
      options.merge!(type: false,
                     subject: false,
                     id: true,
                     all_link: true)
    else
      options.reverse_merge!(type: true,
                             subject: true,
                             id: true)
    end

    parts = { prefix: [],
              hidden_link: [],
              link: [],
              suffix: [],
              title: [],
              css_class: ['issue'] }

    # Prefix part

    parts[:prefix] << "#{package.project}" if options[:project]

    # Link part

    parts[:link] << h(options[:before_text].to_s) if options[:before_text]

    parts[:link] << h(package.kind.to_s) if options[:type]

    parts[:link] << "##{h(package.id)}" if options[:id]

    parts[:link] << "#{h(package.status)}" if options[:id] && options[:status] && package.status

    # Hidden link part

    if package.closed?
      parts[:hidden_link] << content_tag(:span,
                                         I18n.t(:label_closed_work_packages),
                                         class: 'hidden-for-sighted')

      parts[:css_class] << 'closed'
    end

    # Suffix part

    if options[:subject]
      subject = if options[:subject]
                  subject = package.subject
                  if options[:truncate]
                    subject = truncate(subject, length: options[:truncate])
                  end

                  subject
                end

      parts[:suffix] << h(subject)
    end

    # title part

    parts[:title] << package.subject

    # combining

    prefix = parts[:prefix].join(' ')
    suffix = parts[:suffix].join(' ')
    link = parts[:link].join(' ').strip
    hidden_link = parts[:hidden_link].join('')
    title = parts[:title].join(' ')
    css_class = parts[:css_class].join(' ')

    text = if options[:all_link]
             link_text = [prefix, link].reject(&:empty?).join(' - ')
             link_text = [link_text, suffix].reject(&:empty?).join(': ')
             link_text = [hidden_link, link_text].reject(&:empty?).join('')

             link_to(link_text.html_safe,
                     work_package_path(package),
                     title: title,
                     class: css_class)
           else
             link_text = [hidden_link, link].reject(&:empty?).join('')

             html_link = link_to(link_text.html_safe,
                                 work_package_path(package),
                                 title: title,
                                 class: css_class)

             [[prefix, html_link].reject(&:empty?).join(' - '),
              suffix].reject(&:empty?).join(': ')
            end.html_safe
  end

  def work_package_quick_info(work_package)
    changed_dates = {}

    journals = work_package.journals.where(['created_at >= ?', Date.today.to_time - 7.day])
               .order('created_at desc')

    journals.each do |journal|
      break if changed_dates['start_date'] && changed_dates['due_date']

      ['start_date', 'due_date'].each do |date|
        if changed_dates[date].nil? &&
           journal.changed_data[date] &&
           journal.changed_data[date].first
          changed_dates[date] = " (<del>#{journal.changed_data[date].first}</del>)".html_safe
        end
      end
    end

    link = link_to_work_package(work_package, status: true)
    link += " #{work_package.start_date.nil? ? '[?]' : work_package.start_date.to_s}"
    link += changed_dates['start_date']
    link += " – #{work_package.due_date.nil? ? '[?]' : work_package.due_date.to_s}"
    link += changed_dates['due_date']

    link
  end

  def work_package_quick_info_with_description(work_package, lines = 3)
    description = truncated_work_package_description(work_package, lines)

    link = work_package_quick_info(work_package)

    attributes = info_user_attributes(work_package)

    link += content_tag(:div, attributes, class: 'indent quick_info attributes')

    link += content_tag(:div, description, class: 'indent quick_info description')

    link
  end

  def work_package_list(work_packages, &_block)
    ancestors = []
    work_packages.each do |work_package|
      while ancestors.any? && !work_package.is_descendant_of?(ancestors.last)
        ancestors.pop
      end
      yield work_package, ancestors.size
      ancestors << work_package unless work_package.leaf?
    end
  end

  def send_notification_option(checked = false)
    content_tag(:label, for: 'send_notification', class: 'form--label-with-check-box') do
      (content_tag 'span', class: 'form--check-box-container' do
        boxes = hidden_field_tag('send_notification', '0', id: nil)

        boxes += check_box_tag('send_notification',
                               '1',
                               checked,
                               class: 'form--check-box')
        boxes
      end) + l(:label_notify_member_plural)
    end
  end

  def render_work_package_tree_row(work_package, level, relation)
    css_classes = ['work-package']
    css_classes << "work-package-#{work_package.id}"
    css_classes << 'idnt' << "idnt-#{level}" if level > 0

    if relation == 'root'
      issue_text = link_to("#{work_package}",
                           'javascript:void(0)',
                           style: 'color:inherit; font-weight: bold; text-decoration:none; cursor:default;')
    else
      title = []

      if relation == 'parent'
        title << content_tag(:span, l(:description_parent_work_package), class: 'hidden-for-sighted')
      elsif relation == 'child'
        title << content_tag(:span, l(:description_sub_work_package), class: 'hidden-for-sighted')
      end

      issue_text = link_to(work_package.to_s, work_package_path(work_package))
    end

    content_tag :tr, class: css_classes.join(' ') do
      concat content_tag :td, check_box_tag('ids[]', work_package.id, false, id: nil), class: 'checkbox'
      concat content_tag :td, issue_text, class: 'subject'
      concat content_tag :td, h(work_package.status)
      concat content_tag :td, link_to_user(work_package.assigned_to)
      concat content_tag :td, link_to_version(work_package.fixed_version)
    end
  end

  # Returns a string of css classes that apply to the issue
  def work_package_css_classes(work_package)
    # TODO: remove issue once css is cleaned of it
    s = 'issue work_package'.html_safe
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
      work_package_form_category_attribute(form, work_package, locals),
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

  def work_package_show_attribute_list(work_package)
    main_attributes = work_package_show_main_attributes(work_package)
    custom_field_attributes = work_package_show_custom_fields(work_package)
    core_attributes = (main_attributes | custom_field_attributes).compact

    hook_attributes(work_package, core_attributes).compact
  end

  def group_work_package_attributes(attribute_list)
    attributes = {}
    attributes[:left], attributes[:right] = attribute_list.each_slice((attribute_list.count + 1) / 2).to_a

    attributes
  end

  def work_package_show_attributes(work_package)
    group_work_package_attributes work_package_show_attribute_list(work_package)
  end

  def work_package_show_dd_dt(attribute, css_class = nil, attribute_lang = nil, value_lang = nil, &block)
    css_classes = if css_class.nil?
                    ["-#{attribute.to_s.dasherize}"]
                  else
                    css_class.to_s.split(' ').map { |k| "-#{k}" }
                  end

    attribute_string = if attribute.is_a?(Symbol)
                         WorkPackage.human_attribute_name(attribute)
                       else
                         attribute
                       end

    content = content_tag(:dt, attribute_string,
                          class: %w(attributes-key-value--key) + css_classes,
                          lang: attribute_lang)
    content << content_tag(:dd,
                           class: %w(attributes-key-value--value-container) + css_classes,
                           lang: value_lang) do
      content_tag(:div, class: 'attributes-key-value--value', &block)
    end

    WorkPackageAttribute.new(attribute, content)
  end
  deprecated_alias :work_package_show_table_row, :work_package_show_dd_dt

  def work_package_show_status_attribute(work_package)
    work_package_show_dd_dt(:status) do
      work_package.status ?
        work_package.status.name :
        empty_element_tag
    end
  end

  def work_package_show_start_date_attribute(work_package)
    work_package_show_dd_dt(:start_date, 'start-date') do
      work_package.start_date ?
        format_date(work_package.start_date) :
        empty_element_tag
    end
  end

  def work_package_show_priority_attribute(work_package)
    work_package_show_dd_dt(:priority) do
      work_package.priority ?
        work_package.priority.name :
        empty_element_tag
    end
  end

  def work_package_show_due_date_attribute(work_package)
    work_package_show_dd_dt(:due_date) do
      work_package.due_date ?
        format_date(work_package.due_date) :
        empty_element_tag
    end
  end

  def work_package_show_assigned_to_attribute(work_package)
    work_package_show_dd_dt(:assigned_to) do
      content = avatar(work_package.assigned_to, class: 'avatar-mini').html_safe
      content << (work_package.assigned_to ? link_to_user(work_package.assigned_to) : empty_element_tag)
      content
    end
  end

  def work_package_show_responsible_attribute(work_package)
    work_package_show_dd_dt(:responsible) do
      content = avatar(work_package.responsible, class: 'avatar-mini').html_safe
      content << (work_package.responsible ? link_to_user(work_package.responsible) : empty_element_tag)
      content
    end
  end

  def work_package_show_progress_attribute(work_package)
    return if WorkPackage.done_ratio_disabled?

    work_package_show_dd_dt(:progress, 'done-ratio') do
      progress_bar work_package.done_ratio, width: '80px', legend: work_package.done_ratio.to_s
    end
  end

  def work_package_show_category_attribute(work_package)
    work_package_show_dd_dt(:category) do
      work_package.category ?
        work_package.category.name :
        empty_element_tag
    end
  end

  def work_package_show_spent_time_attribute(work_package)
    work_package_show_dd_dt(:spent_time) do
      work_package.spent_hours > 0 ?
        link_to(l_hours(work_package.spent_hours), work_package_time_entries_path(work_package)) :
        empty_element_tag
    end
  end

  def work_package_show_fixed_version_attribute(work_package)
    work_package_show_dd_dt(:fixed_version) do
      work_package.fixed_version ?
        link_to_version(work_package.fixed_version) :
        empty_element_tag
    end
  end

  def work_package_show_estimated_hours_attribute(work_package)
    work_package_show_dd_dt(:estimated_hours) do
      work_package.estimated_hours ?
        l_hours(work_package.estimated_hours) :
        empty_element_tag
    end
  end

  def work_package_form_field(required: false, classes: '')
    div_class = 'form--field -wide-label -break-words'
    div_class << " #{classes}"
    div_class << ' -required' if required

    content_tag 'div', class: div_class do
      yield
    end
  end

  def work_package_form_type_selectable_types(project)
    project.types.map { |t| [((t.is_standard) ? '' : t.name), t.id] }
  end

  def work_package_form_type_observable_url(work_package, project)
    if work_package.new_record?
      new_type_project_work_packages_path(project)
    else
      new_type_work_package_path(work_package)
    end
  end

  def user_can_manage_subtasks?(project)
    User.current.allowed_to?(:manage_subtasks, project)
  end

  def work_package_form_parent_autocomplete_path(work_package, project)
    work_packages_auto_complete_path(id: work_package, project_id: project, escape: false)
  end

  def work_package_form_status_attribute(form, work_package, locals = {})
    new_statuses = work_package.new_statuses_allowed_to(locals[:user])

    field = if new_statuses.any?
              work_package_form_field do
                form.select(:status_id,
                            new_statuses.map { |p| [p.name, p.id] },
                            required: true)
              end
            elsif work_package.status
              work_package_form_field do
                form.label(:status, class: 'form--label') + wrap_text(work_package.status.name)
              end
            else
              form.label(:status) + empty_element_tag
            end

    WorkPackageAttribute.new(:status, field)
  end

  def work_package_form_priority_attribute(form, work_package, locals = {})
    field = work_package_form_field do
      form.select(:priority_id,
                  locals[:priorities].map { |p| [p.name, p.id] },
                  { required: true },
                  disabled: attrib_disabled?(work_package, 'priority_id'))
    end

    WorkPackageAttribute.new(:priority, field)
  end

  def work_package_form_assignee_attribute(form, work_package, _locals = {})
    field = work_package_form_field do
      form.select(:assigned_to_id,
                  work_package.assignable_assignees.map { |m| [m.name, m.id] },
                  include_blank: true)
    end

    WorkPackageAttribute.new(:assignee, field)
  end

  def work_package_form_responsible_attribute(form, work_package, _locals = {})
    field = work_package_form_field do
      form.select(:responsible_id,
                  work_package.assignable_responsibles.map { |m| [m.name, m.id] },
                  include_blank: true)
    end

    WorkPackageAttribute.new(:responsible, field)
  end

  def work_package_form_category_attribute(form, _work_package, locals = {})
    return if locals[:project].categories.empty?

    category_field = work_package_form_field do
      label = form.label(:category_id)

      field = content_tag(:span, class: 'form--field-container') do
        field = form.select(:category_id,
                            (locals[:project].categories.map { |c| [c.name, c.id] }),
                            include_blank: true,
                            no_label: true)

        if authorize_for('categories', 'new')

          field += prompt_to_remote(icon_wrapper('icon icon-add icon4',
                                                 I18n.t(:label_work_package_category_new)),
                                    I18n.t(:label_work_package_category_new),
                                    'category[name]',
                                    project_categories_path(locals[:project]),
                                    class: 'no-decoration-on-hover form--field-inline-action',
                                    title: I18n.t(:label_work_package_category_new))
        end

        field
      end

      label + field
    end

    WorkPackageAttribute.new(:category, category_field)
  end

  def work_package_form_assignable_versions_attribute(form, work_package, locals = {})
    return if work_package.assignable_versions.empty?

    version_field = work_package_form_field do
      label = form.label(:fixed_version_id)

      field = content_tag(:span, class: 'form--field-container') do
        field = form.select(:fixed_version_id,
                            version_options_for_select(work_package.assignable_versions,
                                                       work_package.fixed_version),
                            include_blank: true,
                            no_label: true)

        if authorize_for('versions', 'new')
          field += prompt_to_remote(icon_wrapper('icon icon-add icon4',
                                                 I18n.t(:label_version_new)),
                                    l(:label_version_new),
                                    'version[name]',
                                    project_versions_path(locals[:project]),
                                    class: 'no-decoration-on-hover form--field-inline-action',
                                    title: l(:label_version_new))
        end

        field
      end

      label + field
    end

    WorkPackageAttribute.new(:fixed_version, version_field)
  end

  def work_package_form_start_date_attribute(form, work_package, _locals = {})
    start_date_field = work_package_form_field do
      field = form.text_field :start_date,
                              size: 10,
                              disabled: attrib_disabled?(work_package, 'start_date'),
                              class: 'short'
      field += calendar_for("#{form.object_name}_start_date") unless attrib_disabled?(work_package, 'start_date')

      field
    end

    WorkPackageAttribute.new(:start_date, start_date_field)
  end

  def work_package_form_due_date_attribute(form, work_package, _locals = {})
    due_date_field = work_package_form_field do
      field = form.text_field(:due_date,
                              size: 10,
                              disabled: attrib_disabled?(work_package, 'due_date'),
                              class: 'short')
      field += calendar_for("#{form.object_name}_due_date") unless attrib_disabled?(work_package, 'due_date')

      field
    end

    WorkPackageAttribute.new(:due_date, due_date_field)
  end

  def work_package_form_estimated_hours_attribute(form, work_package, _locals = {})
    field = work_package_form_field do
      form.text_field :estimated_hours,
                      size: 3,
                      disabled: attrib_disabled?(work_package, 'estimated_hours'),
                      value: number_with_precision(work_package.estimated_hours, precision: 2),
                      class: 'short',
                      placeholder: TimeEntry.human_attribute_name(:hours)
    end

    WorkPackageAttribute.new(:estimated_hours, field)
  end

  def work_package_form_done_ratio_attribute(form, work_package, _locals = {})
    if !attrib_disabled?(work_package, 'done_ratio') && WorkPackage.use_field_for_done_ratio?

      field = work_package_form_field do
        form.select(:done_ratio, ((0..10).to_a.map { |r| ["#{r * 10} %", r * 10] }))
      end

      WorkPackageAttribute.new(:done_ratio, field)
    end
  end

  def work_package_form_custom_values_attribute(_form, work_package, _locals = {})
    fields = work_package.custom_field_values.map do |value|
      field = _form.fields_for_custom_fields :custom_field_values, value do |value_form|
        work_package_form_field required: value.custom_field.is_required? do
          value_form.custom_field
        end
      end

      WorkPackageAttribute.new(:"work_package_#{value.id}", field)
    end
  end

  def work_package_associations_to_address(associated)
    ret = ''.html_safe

    ret += content_tag(:p, l(:text_destroy_with_associated), class: 'bold')

    ret += content_tag(:ul) do
      associated.inject(''.html_safe) do |list, associated_class|
        list += content_tag(:li, associated_class.model_name.human, class: 'decorated')

        list
      end
    end

    ret
  end

  private

  def work_package_show_custom_fields(work_package)
    work_package.custom_field_values.each_with_object([]) do |v, a|
      a << work_package_show_dd_dt(v.custom_field.name,
                                   "custom_field cf_#{v.custom_field_id}",
                                   v.custom_field.name_locale,
                                   v.custom_field.default_value_locale) do
        v.value.blank? ? empty_element_tag : simple_format_without_paragraph(h(show_value(v)))
      end
    end
  end

  def hook_attributes(work_package, attributes = [])
    call_hook(:work_packages_show_attributes,
              work_package: work_package,
              project: @project,
              attributes: attributes)
    attributes
  end

  def work_package_show_main_attributes(work_package)
    [
      work_package_show_status_attribute(work_package),
      work_package_show_priority_attribute(work_package),
      work_package_show_assigned_to_attribute(work_package),
      work_package_show_responsible_attribute(work_package),
      work_package_show_category_attribute(work_package),
      work_package_show_estimated_hours_attribute(work_package),
      work_package_show_start_date_attribute(work_package),
      work_package_show_due_date_attribute(work_package),
      work_package_show_progress_attribute(work_package),
      work_package_show_spent_time_attribute(work_package),
      work_package_show_fixed_version_attribute(work_package)
    ]
  end

  def truncated_work_package_description(work_package, lines = 3)
    description_lines = work_package.description.to_s.lines.to_a[0, lines]

    if description_lines[lines - 1] && work_package.description.to_s.lines.to_a.size > lines
      description_lines[lines - 1].strip!

      while !description_lines[lines - 1].end_with?('...')
        description_lines[lines - 1] = description_lines[lines - 1] + '.'
      end
    end

    if work_package.description.blank?
      empty_element_tag
    else
      format_text(description_lines.join(''))
    end
  end

  def info_user_attributes(work_package)
    responsible = if work_package.responsible_id.present?
                    "<span class='label'>#{WorkPackage.human_attribute_name(:responsible)}:</span> " +
                    "#{h(work_package.responsible.name)}"
                  end

    assignee = if work_package.assigned_to_id.present?
                 "<span class='label'>#{WorkPackage.human_attribute_name(:assigned_to)}:</span> " +
                 "#{h(work_package.assigned_to.name)}"
               end

    [responsible, assignee].compact.join('<br>').html_safe
  end

  def wrap_text(name)
    content_tag :span, class: 'form--field-container' do
      content_tag :span, name, class: 'form--text-field-container'
    end
  end
end
