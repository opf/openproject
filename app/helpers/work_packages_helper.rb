#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module WorkPackagesHelper
  include AccessibilityHelper
  extend DeprecatedAlias

  # Displays a link to +work_package+ with its subject.
  # Examples:
  #
  #   link_to_work_package(package)                             # => Defect #6: This is the subject
  #   link_to_work_package(package, all_link: true)          # => Defect #6: This is the subject (everything within the link)
  #   link_to_work_package(package, truncate: 9)             # => Defect #6: This i...
  #   link_to_work_package(package, subject: false)          # => Defect #6
  #   link_to_work_package(package, type: false)             # => #6: This is the subject
  #   link_to_work_package(package, project: true)           # => Foo - Defect #6
  #   link_to_work_package(package, id_only: true)           # => #6
  #   link_to_work_package(package, subject_only: true)      # => This is the subject (as link)
  #   link_to_work_package(package, status: true)            # => #6 New (if #id => true)
  def link_to_work_package(package, options = {})
    only_path = options.fetch(:only_path) { true }
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

    parts[:link] << h(package.type.to_s) if options[:type]

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

    parts[:title] << (options[:title].nil? ? package.subject : options[:title])

    # combining

    prefix = parts[:prefix].join(' ')
    suffix = parts[:suffix].join(' ')
    link = parts[:link].join(' ').strip
    hidden_link = parts[:hidden_link].join('')
    title = parts[:title].join(' ')
    css_class = parts[:css_class].join(' ')
    css_class << options[:class].to_s

    # Determine path or url
    work_package_link =
      if only_path
        work_package_path(package)
      else
        work_package_url(package)
      end

    text = if options[:all_link]
             link_text = [prefix, link].reject(&:empty?).join(' - ')
             link_text = [link_text, suffix].reject(&:empty?).join(': ')
             link_text = [hidden_link, link_text].reject(&:empty?).join('')

             link_to(link_text.html_safe,
                     work_package_link,
                     title: title,
                     class: css_class)
           else
             link_text = [hidden_link, link].reject(&:empty?).join('')

             html_link = link_to(link_text.html_safe,
                                 work_package_link,
                                 title: title,
                                 class: css_class)

             [[prefix, html_link].reject(&:empty?).join(' - '),
              suffix].reject(&:empty?).join(': ')
            end.html_safe
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

  # Returns a string of css classes that apply to the issue
  def work_package_css_classes(work_package)
    # TODO: remove issue once css is cleaned of it
    s = 'issue work_package preview-trigger'.html_safe
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

  def work_package_associations_to_address(associated)
    ret = ''.html_safe

    ret += content_tag(:p, l(:text_destroy_with_associated), class: 'bold')

    ret += content_tag(:ul) {
      associated.inject(''.html_safe) do |list, associated_class|
        list += content_tag(:li, associated_class.model_name.human, class: 'decorated')

        list
      end
    }

    ret
  end

  private

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
      ::OpenProject::TextFormatting::Renderer.format_text(
        description_lines.join(''),
        object: work_package,
        attribute: :description,
        no_nesting: true
      )
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
end
