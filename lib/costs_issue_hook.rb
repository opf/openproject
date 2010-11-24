# Hooks to attach to the Redmine Issues.
class CostsIssueHook  < Redmine::Hook::ViewListener
  # Renders the Cost Object subject and basic costs information
  render_on :view_issues_show_details_bottom, :partial => 'hooks/view_issues_show_details_bottom'
  
  # Renders Costs links in the issue view sidebar
  render_on :view_issues_sidebar_planning_bottom, :partial => 'hooks/view_issues_sidebar_planning_bottom'
  
  # Renders a select tag with all the Cost Objects
  render_on :view_issues_form_details_bottom, :partial => 'hooks/view_issues_form_details_bottom'
  
  # Renders a select tag with all the Cost Objects for the bulk edit page
  render_on :view_issues_bulk_edit_details_bottom, :partial => 'hooks/view_issues_bulk_edit_details_bottom'
  
  render_on :view_issues_move_bottom, :partial => 'hooks/view_issues_move_bottom'
  
  render_on :view_issues_context_menu_end, :partial => 'hooks/view_issues_context_menu_end'
  
  
  # Updates the cost object after a move
  # 
  # Context:
  # * params => Request parameters
  # * issue => Issue to move
  # * target_project => Target of the move
  # * copy => true, if the issues are copied rather than moved
  def controller_issues_move_before_save(context={})
    # FIXME: In case of copy==true, this will break stuff if the original issue is saved

    cost_object_id = context[:params] && context[:params][:cost_object_id]
    case cost_object_id
    when "" # a.k.a "(No change)"
      # cost objects HAVE to be changed if move is performed across project boundaries
      # as the are project specific
      context[:issue].cost_object_id = nil unless (context[:issue].project == context[:target_project])
    when "none"
      context[:issue].cost_object_id = nil
    else
      context[:issue].cost_object_id = cost_object_id
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
  
  # Cost Object changes for the journal use the Cost Object subject
  # instead of the id
  #
  # Context:
  # * :detail => Detail about the journal change
  #
  def helper_issues_show_detail_after_setting(context = { })
    # FIXME: Overwritting the caller is bad juju
    if (context[:detail].prop_key == 'cost_object_id')
      if context[:detail].value.to_i.to_s == context[:detail].value.to_s
        d = CostObject.find_by_id(context[:detail].value)
        context[:detail].value = d.subject unless d.nil? || d.subject.nil?
      end

      if context[:detail].old_value.to_i.to_s == context[:detail].old_value.to_s
        d = CostObject.find_by_id(context[:detail].old_value)
        context[:detail].old_value = d.subject unless d.nil? || d.subject.nil?
      end
    end
    ''
  end
end
