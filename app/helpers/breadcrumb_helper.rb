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

module BreadcrumbHelper
  def full_breadcrumb
    breadcrumb_list(link_to(l(:label_home), home_path),
                    link_to_project_ancestors(@project),
                    *breadcrumb_paths)
  end

  def breadcrumb(*args)
    elements = args.flatten
    elements.any? ? content_tag('p', (args.join(' &#187; ') + ' &#187; ').html_safe, :class => 'breadcrumb') : nil
  end

  def breadcrumb_list(*args)
    elements = args.flatten
    cutme_elements = []
    breadcrumb_elements = [content_tag(:li, elements.shift.to_s, :class => 'first-breadcrumb-element', :style => 'list-style-image:none;')]

    breadcrumb_elements += elements.collect do |element|
      content_tag(:li, h(element.to_s)) if element
    end

    content_tag(:ul, breadcrumb_elements.join.html_safe, :class => 'breadcrumb')
  end

  def breadcrumb_paths(*args)
    if args.nil?
      nil
    elsif args.empty?
      @breadcrumb_paths ||= [default_breadcrumb]
    else
      @breadcrumb_paths ||= []
      @breadcrumb_paths += args
    end
  end

  private

  def link_to_project_ancestors(project)
    if project && !project.new_record?
      ancestors = (project.root? ? [] : project.ancestors.visible)
      ancestors << project
      ancestors.collect do |p|
        if p == project
          link_to_project(p, {:jump => current_menu_item}, {:title => p, :class => 'breadcrumb-project-title nocut'}).html_safe
        else
          link_to_project(p, {:jump => current_menu_item}, {:title => p}).html_safe
        end
      end
    end
  end
end
