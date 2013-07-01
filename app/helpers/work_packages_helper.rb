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
end
