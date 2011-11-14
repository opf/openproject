#-- encoding: UTF-8
module OpenIdAuthentication
  class Nonce < ActiveRecord::Base
    set_table_name :open_id_authentication_nonces
  end
end
