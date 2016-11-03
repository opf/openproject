class License < ActiveRecord::Base

  validates_presence_of :encoded_license
  validate :encoded_license_is_valid

  after_save :update_license_service

  def self.current
    License.order('created_at DESC').first
  end

  private
    def encoded_license_is_valid
      begin
        OpenProject::License.import(encoded_license)
      rescue OpenProject::License::ImportError => error
        errors.add(:encoded_license, "can't be importet. Sure it is a license?")
      end
    end

    def update_license_service
      
    end

end
