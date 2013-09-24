#class OpenProject::Backlogs::IssueActions < OpenProject::Nissue::View
#  def initialize(work_package)
#    @work_package = work_package
#  end
#
#  def render(t)
#    css_class = "watcher_link_#{@work_package.id}"
#    content_tag(:div, [
#        (t.modal_link_to(l(:button_update), {:controller => '/work_package_boxes', :action => 'edit', :id => @work_package }, :class => 'icon icon-edit') if t.authorize_for('work_package_boxes', 'edit')),
#        t.watcher_link(@work_package, User.current, :class => css_class, :replace => ".#{css_class}")
#      ].join.html_safe, :class => 'contextual')
#  end
#end
