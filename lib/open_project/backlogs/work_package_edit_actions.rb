#class OpenProject::Backlogs::IssueEditActions < OpenProject::Nissue::View
#  attr_reader :html_id
#
#  def initialize(work_package, html_id, form_id)
#    @work_package = work_package
#    @html_id = html_id
#    @form_id = form_id
#  end
#
#  def render(t)
#    content_tag(:div, [
#        t.link_to_work_package_box(l(:button_cancel), @work_package, :class => 'icon icon-cancel'),
#        (t.link_to_remote(l(:button_save),
#                           { :url => { :controller => '/work_package_boxes', :action => 'update', :id => @work_package },
#                             :method => 'PUT',
#                             :update => @html_id,
#                             :with => "Form.serialize('#{@form_id}')"
#                           }, { :class => 'icon icon-save', :accesskey => t.accesskey(:update) }) if t.authorize_for('work_package_boxes', 'update'))
#      ].join.html_safe, :class => 'contextual')
#  end
#end
