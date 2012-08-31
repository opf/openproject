#-- encoding: UTF-8
class Developer < ActiveRecord::Base
  has_and_belongs_to_many :projects
end

class DeVeLoPeR < ActiveRecord::Base
  self.table_name = "developers"
end
