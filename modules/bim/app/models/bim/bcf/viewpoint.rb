module Bim::Bcf
  class Viewpoint < ActiveRecord::Base
    self.table_name = :bcf_viewpoints

    include InitializeWithUuid

    acts_as_attachable view_permission: :view_linked_issues,
                       delete_permission: :manage_bcf,
                       add_on_new_permission: :manage_bcf,
                       add_on_persisted_permission: :manage_bcf

    def self.has_uuid?(uuid)
      where(uuid: uuid).exists?
    end

    belongs_to :issue,
               foreign_key: :issue_id,
               class_name: "Bim::Bcf::Issue",
               touch: true

    has_many :comments, foreign_key: :viewpoint_id, class_name: "Bim::Bcf::Comment"
    delegate :project, :project_id, to: :issue, allow_nil: true

    validates :issue, presence: true

    def raw_json_viewpoint
      attributes_before_type_cast['json_viewpoint']
    end

    def snapshot
      if attachments.loaded?
        attachments.detect { |a| a.description == 'snapshot' }
      else
        attachments.find_by_description('snapshot')
      end
    end

    def clipping_planes?
      json_viewpoint && json_viewpoint["clipping_planes"]
    end

    def snapshot=(file)
      snapshot&.destroy
      build_snapshot file
    end

    def build_snapshot(file, user: User.current)
      ::Attachments::BuildService
        .new(user: user)
        .call(file: file, container: self, filename: file.original_filename, description: 'snapshot')
        .result
    end
  end
end
