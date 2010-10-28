class PrincipalRole < ActiveRecord::Base
  belongs_to :principal
  belongs_to :role
end