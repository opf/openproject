module PrintableIssues
  class IssueHook  < Redmine::Hook::ViewListener
    # Add XLS format link below issue list
    def view_work_packages_index_other_formats(context)
      links = [
        link_to_xls(I18n.t(:label_xls), context),
        link_to_xls(I18n.t(:label_xls_with_descriptions), context, show_descriptions: true),
        link_to_xls(I18n.t(:label_xls_with_relations), context, show_relations: true)
      ]

      links.join(" ")
    end

    def link_to_xls(context, label, options = {})
      url = {
        project_id: context[:project],
        format: "xls"
      }

      context[:link_formatter].link_to label, url: url.merge(options)
    end
  end
end
