# ToDo: Copyright notice missing
# Purpose: ???
# Used by: ???
# Reference: ToDo: Link to documentation about queries

# Why is there a Queries::Storages namespace?
class Queries::Storages::FileLinks::FileLinkQuery < Queries::BaseQuery
  # What is class << self?
  class << self
    # Why model?
    def model
      # Where is the model needed? From where is it called?
      # ToDo: What is constantize?
      @model ||= '::Storages::FileLink'.constantize
    end
  end
end
