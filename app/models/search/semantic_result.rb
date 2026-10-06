# frozen_string_literal: true

module Search
  class SemanticResult
    def self.ids(_query, user)
      WorkPackage.visible(user).limit(3).pluck(:id)
    end
  end
end
