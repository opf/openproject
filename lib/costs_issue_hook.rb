# Hooks to attach to the Redmine Issues.
class CostsIssueHook  < Redmine::Hook::ViewListener
  # Renders the Deliverable subject and basic costs information
  render_on :view_issues_show_details_bottom, :partial => 'hooks/view_issues_show_details_bottom'
  
  # Renders Costs links in the issue view sidebar
  render_on :view_issues_sidebar_issues_bottom, :partial => 'hooks/view_issues_sidebar_issues_bottom'
  
  # Renders a select tag with all the Deliverables
  render_on :view_issues_form_details_bottom, :partial => 'hooks/view_issues_form_details_bottom'
  
  # Renders a select tag with all the Deliverables for the bulk edit page
  render_on :view_issues_bulk_edit_details_bottom, :partial => 'hooks/view_issues_bulk_edit_details_bottom'
  
  
  
  # Renders a select tag with all the Deliverables for the bulk edit page
  #
  # Context:
  # * :project => Current project
  #
  def view_issues_bulk_edit_details_bottom(context = { })
    if context[:project].module_enabled?('budget_module')
      select = select_tag('deliverable_id',
                               content_tag('option', l(:label_no_change_option), :value => '') +
                               content_tag('option', l(:label_none), :value => 'none') +
                               options_from_collection_for_select(Deliverable.find_all_by_project_id(context[:project].id, :order => 'subject ASC'), :id, :subject))
    
      return content_tag(:p, "<label>#{l(:field_deliverable)}: " + select + "</label>")
    else
      return ''
    end
  end
  
  # Saves the Deliverable assignment to the issue
  #
  # Context:
  # * :issue => Issue being saved
  # * :params => HTML parameters
  #
  def controller_issues_bulk_edit_before_save(context = { })
    case true

    when context[:params][:deliverable_id].blank?
      # Do nothing
    when context[:params][:deliverable_id] == 'none'
      # Unassign deliverable
      context[:issue].deliverable = nil
    else
      context[:issue].deliverable = Deliverable.find(context[:params][:deliverable_id])
    end

    return ''
  end
  
  # Deliverable changes for the journal use the Deliverable subject
  # instead of the id
  #
  # Context:
  # * :detail => Detail about the journal change
  #
  def helper_issues_show_detail_after_setting(context = { })
    # TODO Later: Overwritting the caller is bad juju
    if context[:detail].prop_key == 'deliverable_id'
      d = Deliverable.find_by_id(context[:detail].value)
      context[:detail].value = d.subject unless d.nil? || d.subject.nil?

      d = Deliverable.find_by_id(context[:detail].old_value)
      context[:detail].old_value = d.subject unless d.nil? || d.subject.nil?      
    end
    ''
  end
end
