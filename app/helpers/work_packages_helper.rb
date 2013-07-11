module WorkPackagesHelper
  def work_package_breadcrumb
    full_path = ancestors_links.unshift(work_package_index_link)

    breadcrumb_paths(*full_path)
  end

  def ancestors_links
    ancestors = controller.ancestors.map do |parent|
      link_to '#' + h(parent.id), work_package_path(parent.id)
    end
  end

  def work_package_index_link
    # TODO: will need to change to work_package index
    link_to(t(:label_issue_plural), {:controller => '/issues', :action => 'index'})
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

  def render_work_package_tree_row(work_package, level, relation)
    css_classes = ["work-package"]
    css_classes << "work-package-#{work_package.id}"
    css_classes << "idnt" << "idnt-#{level}" if level > 0

    if relation == "root"
      issue_text = link_to("#{(work_package.kind.nil?) ? '' : h(work_package.kind.name)} ##{work_package.id}",
                             'javascript:void(0)',
                             :style => "color:inherit; font-weight: bold; text-decoration:none; cursor:default;")
    else
      title = []

      if relation == "parent"
        title << content_tag(:span, l(:description_parent_work_package), :class => "hidden-for-sighted")
      elsif relation == "child"
        title << content_tag(:span, l(:description_sub_work_package), :class => "hidden-for-sighted")
      end
      title << ((work_package.kind.nil?) ? '' : h(work_package.kind.name))
      title << "##{work_package.id}"

      issue_text = link_to(title.join(' ').html_safe, work_package_path(work_package))
    end
    issue_text << ": "
    issue_text << truncate(work_package.subject, :length => 60)

    content_tag :tr, :class => css_classes.join(' ') do
      concat content_tag :td, check_box_tag("ids[]", work_package.id, false, :id => nil), :class => 'checkbox'
      concat content_tag :td, issue_text, :class => 'subject'
      concat content_tag :td, h(work_package.status)
      concat content_tag :td, link_to_user(work_package.assigned_to)
      concat content_tag :td, link_to_version(work_package.fixed_version)
    end
  end
end
