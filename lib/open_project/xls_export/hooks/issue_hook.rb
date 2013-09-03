module PrintableIssues
  class IssueHook  < Redmine::Hook::ViewListener
    # Add XLS format link below issue list
    def view_issues_index_other_formats(context)
      (context[:link_formatter].link_to 'XLS', :url => { :project_id => context[:project] }) +
      ' ' +
      (context[:link_formatter].link_to I18n.t(:xls_with_descriptions),
                                        :url => { :project_id => context[:project],
                                                  :show_descriptions => true,
                                                  :format => 'xls' })
    end
  end
end
