# Hooks to attach to the Redmine Issues.
class CostsIssueHook  < Redmine::Hook::ViewListener
  # Renders the Cost Object subject and basic costs information
  render_on :view_issues_show_details_bottom, :partial => 'hooks/view_issues_show_details_bottom'
  
  # Renders Costs links in the issue view sidebar
  render_on :view_issues_sidebar_issues_bottom, :partial => 'hooks/view_issues_sidebar_issues_bottom'
  
  # Renders a select tag with all the Cost Objects
  render_on :view_issues_form_details_bottom, :partial => 'hooks/view_issues_form_details_bottom'
  
  # Renders a select tag with all the Cost Objects for the bulk edit page
  render_on :view_issues_bulk_edit_details_bottom, :partial => 'hooks/view_issues_bulk_edit_details_bottom'
  
  
  
  # Renders a select tag with all the Cost Objects for the bulk edit page
  #
  # Context:
  # * :project => Current project
  #
  def view_issues_bulk_edit_details_bottom(context = { })
    if context[:project].module_enabled?('cost_module')
      select = select_tag('cost_object_id',
                               content_tag('option', l(:label_no_change_option), :value => '') +
                               content_tag('option', l(:label_none), :value => 'none') +
                               options_from_collection_for_select(CostObject.find_all_by_project_id(context[:project].id, :order => 'subject ASC'), :id, :subject))
    
      return content_tag(:p, "<label>#{l(:field_cost_object)}: " + select + "</label>")
    else
      return ''
    end
  end
  
  # Saves the Cost Object assignment to the issue
  #
  # Context:
  # * :issue => Issue being saved
  # * :params => HTML parameters
  #
  def controller_issues_bulk_edit_before_save(context = { })
    case true

    when context[:params][:cost_object_id].blank?
      # Do nothing
    when context[:params][:cost_object_id] == 'none'
      # Unassign cost_object
      context[:issue].cost_object = nil
    else
      context[:issue].cost_object = CostObject.find(context[:params][:cost_object_id])
    end

    return ''
  end
  
  # Cost Object changes for the journal use the Deliverable subject
  # instead of the id
  #
  # Context:
  # * :detail => Detail about the journal change
  #
  def helper_issues_show_detail_after_setting(context = { })
    # FIXME: Overwritting the caller is bad juju
    if context[:detail].prop_key == 'cost_object_id'
      d = CostObject.find_by_id(context[:detail].value)
      context[:detail].value = d.subject unless d.nil? || d.subject.nil?

      d = CostObject.find_by_id(context[:detail].old_value)
      context[:detail].old_value = d.subject unless d.nil? || d.subject.nil?      
    end
    ''
  end
end
