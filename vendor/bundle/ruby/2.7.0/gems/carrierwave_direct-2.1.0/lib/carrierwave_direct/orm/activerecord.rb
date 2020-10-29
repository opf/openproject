# encoding: utf-8

# This file tests that a ActiveRecord class that uses a standard CarrierWave uploader
# does not get CarrierWaveDirect validators.

require 'active_record'
require 'carrierwave_direct/validations/active_model'

module CarrierWaveDirect
  module ActiveRecord
    include CarrierWaveDirect::Mount

    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      # Don't go further unless the class included CarrierWaveDirect::Uploader
      return unless uploader.ancestors.include?(CarrierWaveDirect::Uploader)

      uploader.instance_eval <<-RUBY, __FILE__, __LINE__+1
        include ActiveModel::Conversion
        extend ActiveModel::Naming
      RUBY

      include CarrierWaveDirect::Validations::ActiveModel

      validates_is_attached column if uploader_option(column.to_sym, :validate_is_attached)
      validates_is_uploaded column if uploader_option(column.to_sym, :validate_is_uploaded)
      validates_filename_uniqueness_of(column, on: :create) if uploader_option(column.to_sym, :validate_unique_filename)
      validates_filename_format_of(column, on: :create) if uploader_option(column.to_sym, :validate_filename_format)
      validates_remote_net_url_format_of(column, on: :create) if uploader_option(column.to_sym, :validate_remote_net_url_format)

      self.instance_eval <<-RUBY, __FILE__, __LINE__+1
        attr_accessor   :skip_is_attached_validations
        unless defined?(ActiveModel::ForbiddenAttributesProtection) && ancestors.include?(ActiveModel::ForbiddenAttributesProtection)
          attr_accessible :#{column}_key, :remote_#{column}_net_url
        end
      RUBY

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def filename_valid?
          if has_#{column}_upload?
            self.skip_is_attached_validations = true
            valid?
            self.skip_is_attached_validations = false
            column_errors = errors[:#{column}]
            errors.clear
            column_errors.each do |column_error|
              errors.add(:#{column}, column_error)
            end
            errors.empty?
          else
            true
          end
        end
      RUBY
    end
  end
end

ActiveRecord::Base.extend CarrierWaveDirect::ActiveRecord

