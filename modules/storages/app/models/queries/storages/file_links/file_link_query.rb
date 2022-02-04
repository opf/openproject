class Queries::Storages::FileLinks::FileLinkQuery < Queries::BaseQuery
  class << self
    def model
      @model ||= '::Storages::FileLink'.constantize
    end
  end
end
