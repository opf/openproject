# frozen_string_literal: true

class Mngt::ProjectApiId < ApplicationRecord
  self.table_name = "mngt_project_api_ids"

  belongs_to :project
end
