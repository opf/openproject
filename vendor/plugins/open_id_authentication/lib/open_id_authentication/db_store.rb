#-- encoding: UTF-8
require 'openid/store/interface'

module OpenIdAuthentication
  class DbStore < OpenID::Store::Interface
    def self.cleanup_nonces
      now = Time.now.to_i
      Nonce.delete_all(["timestamp > ? OR timestamp < ?", now + OpenID::Nonce.skew, now - OpenID::Nonce.skew])
    end

    def self.cleanup_associations
      now = Time.now.to_i
      Association.delete_all(['issued + lifetime > ?',now])
    end

    def store_association(server_url, assoc)
      remove_association(server_url, assoc.handle)
      Association.create(:server_url => server_url,
                         :handle     => assoc.handle,
                         :secret     => assoc.secret,
                         :issued     => assoc.issued,
                         :lifetime   => assoc.lifetime,
                         :assoc_type => assoc.assoc_type)
    end

    def get_association(server_url, handle = nil)
      assocs = if handle.blank?
          Association.find_all_by_server_url(server_url)
        else
          Association.find_all_by_server_url_and_handle(server_url, handle)
        end

      assocs.reverse.each do |assoc|
        a = assoc.from_record
        if a.expires_in == 0
          assoc.destroy
        else
          return a
        end
      end if assocs.any?

      return nil
    end

    def remove_association(server_url, handle)
      Association.delete_all(['server_url = ? AND handle = ?', server_url, handle]) > 0
    end

    def use_nonce(server_url, timestamp, salt)
      return false if Nonce.find_by_server_url_and_timestamp_and_salt(server_url, timestamp, salt)
      return false if (timestamp - Time.now.to_i).abs > OpenID::Nonce.skew
      Nonce.create(:server_url => server_url, :timestamp => timestamp, :salt => salt)
      return true
    end
  end
end
