class PrincipalGlobalRole < ActiveRecord::Base
  belongs_to :principal
  belongs_to :global_role
end