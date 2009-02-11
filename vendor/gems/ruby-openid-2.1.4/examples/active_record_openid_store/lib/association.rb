require 'openid/association'
require 'time'

class Association < ActiveRecord::Base
  set_table_name 'open_id_associations'
  def from_record
    OpenID::Association.new(handle, secret, Time.at(issued), lifetime, assoc_type)
  end
end

