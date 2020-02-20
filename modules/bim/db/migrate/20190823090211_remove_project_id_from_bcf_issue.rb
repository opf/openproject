class RemoveProjectIdFromBcfIssue < ActiveRecord::Migration[5.1]
  def up
    remove_column :bcf_issues, :project_id
  end

  def down
    add_reference :bcf_issues, :project, foreign_key: { on_delete: :cascade }, index: true

    Bim::Bcf::Issue.includes(:work_package).find_each do |bcf_issue|
      if bcf_issue.work_package
        bcf_issue.project_id = bcf_issue.work_package.project_id
        bcf_issue.save
      end
    end
  end
end
