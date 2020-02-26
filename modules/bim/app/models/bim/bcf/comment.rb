module Bim::Bcf
  class Comment < ActiveRecord::Base
    self.table_name = :bcf_comments

    include InitializeWithUuid

    belongs_to :journal
    belongs_to :issue, foreign_key: :issue_id, class_name: "Bim::Bcf::Issue"
    belongs_to :viewpoint, foreign_key: :viewpoint_id, class_name: "Bim::Bcf::Viewpoint", optional: true

    validates_presence_of :uuid
    validates_uniqueness_of :uuid, scope: [:issue_id]

    def self.has_uuid?(uuid, issue_id)
      where(uuid: uuid, issue_id: issue_id).exists?
    end
  end
end
