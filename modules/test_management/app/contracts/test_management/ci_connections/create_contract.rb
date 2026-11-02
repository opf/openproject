# frozen_string_literal: true

module TestManagement
  module CiConnections
    class CreateContract < BaseContract
      attribute :project
      attribute :created_by
    end
  end
end
