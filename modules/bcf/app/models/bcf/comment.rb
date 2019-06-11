module Bcf
  class Comment < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :journal
    belongs_to :issue, foreign_key: :issue_id, class_name: "Bcf::Issue"

    validates_presence_of :uuid
    validates_uniqueness_of :uuid, scope: [:issue_id]

    def self.has_uuid?(uuid, issue_id)
      where(uuid: uuid, issue_id: issue_id).exists?
    end
  end
end
