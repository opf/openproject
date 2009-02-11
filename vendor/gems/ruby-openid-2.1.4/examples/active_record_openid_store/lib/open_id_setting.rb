class OpenIdSetting < ActiveRecord::Base
  
  validates_uniqueness_of :setting
end
