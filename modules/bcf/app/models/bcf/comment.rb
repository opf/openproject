module Bcf
  class Comment < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :journal
    belongs_to :issue, foreign_key: :issue_id, class_name: "Bcf::Issue"

    validates_presence_of :uuid

    def self.has_uuid?(uuid)
      where(uuid: uuid).exists?
    end
  end
end
