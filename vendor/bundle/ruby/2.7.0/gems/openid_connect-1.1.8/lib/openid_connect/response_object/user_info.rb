module OpenIDConnect
  class ResponseObject
    class UserInfo < ConnectObject
      attr_optional(
        :sub,
        :name,
        :given_name,
        :family_name,
        :middle_name,
        :nickname,
        :preferred_username,
        :profile,
        :picture,
        :website,
        :email,
        :email_verified,
        :gender,
        :birthdate,
        :zoneinfo,
        :locale,
        :phone_number,
        :phone_number_verified,
        :address,
        :updated_at
      )
      alias_method :subject, :sub
      alias_method :subject=, :sub=

      validates :email_verified, :phone_number_verified, allow_nil: true, inclusion: {in: [true, false]}
      validates :zoneinfo,                               allow_nil: true, inclusion: {in: TZInfo::TimezoneProxy.all.collect(&:name)}
      validates :profile, :picture, :website,            allow_nil: true, url: true
      validates :email,                                  allow_nil: true, email: true
      validates :updated_at,                             allow_nil: true, numericality: {only_integer: true}
      validate :validate_address
      validate :require_at_least_one_attributes
      # TODO: validate locale

      def initialize(attributes = {})
        super
        (all_attributes - [:email_verified, :phone_number_verified, :address, :updated_at]).each do |key|
          self.send "#{key}=", self.send(key).try(:to_s)
        end
        self.updated_at = updated_at.try(:to_i)
      end

      def validate_address
        errors.add :address, address.errors.full_messages.join(', ') if address.present? && !address.valid?
      end

      undef :address=
      def address=(hash_or_address)
        @address = case hash_or_address
        when Hash
          Address.new hash_or_address
        when Address
          hash_or_address
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/user_info/*.rb'].each do |file|
  require file
end
