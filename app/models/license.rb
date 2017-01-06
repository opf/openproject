class License < ActiveRecord::Base

  validates_presence_of :encoded_license
  validate :load_license

  after_save :update_license_service
  after_destroy :update_license_service

  def self.current
    License.order('created_at DESC').first
  end

  def load_license
    begin
      OpenProject::License.import(encoded_license)
    rescue OpenProject::License::ImportError => error
      errors.add(:encoded_license, :import_failed)
      nil
    end
  end

  private
    def update_license_service
      LicenseService.instance.update
    end

end
