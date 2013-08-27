module PrintableIssues
  class IssueHook  < Redmine::Hook::ViewListener
    # Add XLS format link below issue list
    def view_issues_index_other_formats(context)
      context[:link_formatter].link_to 'XLS', :url => { :project_id => context[:project].id }
    end
  end
end
