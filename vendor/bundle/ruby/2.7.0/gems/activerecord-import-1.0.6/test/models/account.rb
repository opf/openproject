class Account < ActiveRecord::Base
  self.locking_column = :lock
end
