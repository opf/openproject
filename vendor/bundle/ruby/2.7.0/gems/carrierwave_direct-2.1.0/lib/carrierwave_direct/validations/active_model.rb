# encoding: utf-8

require 'active_model/validator'
require 'active_support/concern'

module CarrierWaveDirect

  module Validations
    module ActiveModel
      extend ActiveSupport::Concern

      class UniqueFilenameValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.errors[attribute].empty? && (record.send("has_#{attribute}_upload?") || record.send("has_remote_#{attribute}_net_url?"))
            column = record.class.uploader_options[attribute].fetch(:mount_on, attribute)
            if record.class.where(column => record.send(attribute).filename).exists?
              record.errors.add(attribute, :carrierwave_direct_filename_taken)
            end
          end
        end
      end

      class FilenameFormatValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.send("has_#{attribute}_upload?") && record.send("#{attribute}_key") !~ record.send(attribute).key_regexp
            extensions = record.send(attribute).extension_whitelist
            message = I18n.t("errors.messages.carrierwave_direct_filename_invalid")

            if extensions.present?
              message += I18n.t("errors.messages.carrierwave_direct_allowed_extensions", :extensions => extensions.to_sentence)
            end

            record.errors.add(attribute, message)
          end
        end
      end

      class RemoteNetUrlFormatValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.send("has_remote_#{attribute}_net_url?")
            remote_net_url = record.send("remote_#{attribute}_net_url")
            uploader = record.send(attribute)
            url_scheme_white_list = uploader.url_scheme_white_list

            if (remote_net_url !~ URI.regexp(url_scheme_white_list) || remote_net_url !~ /#{uploader.extension_regexp}\z/)
              extensions = uploader.extension_whitelist

              message = I18n.t("errors.messages.carrierwave_direct_filename_invalid")

              if extensions.present?
                message += I18n.t("errors.messages.carrierwave_direct_allowed_extensions", :extensions => extensions.to_sentence)
              end

              if url_scheme_white_list.present?
                message += I18n.t("errors.messages.carrierwave_direct_allowed_schemes", :schemes => url_scheme_white_list.to_sentence)
              end

              record.errors.add(:"remote_#{attribute}_net_url", message)
            end
          end
        end
      end

      class IsUploadedValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if record.new_record?
            unless (record.send("has_#{attribute}_upload?") || record.send("has_remote_#{attribute}_net_url?"))
              record.errors.add(
                attribute,
                :carrierwave_direct_upload_missing
              )
              record.errors.add(
                :"remote_#{attribute}_net_url",
                :blank
              )
            end
          end
        end
      end

      class IsAttachedValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          if value.blank? && !record.skip_is_attached_validations
            record.errors.add(
              attribute,
              :carrierwave_direct_attachment_missing
            )
          end
        end
      end

      module HelperMethods

        ##
        # Makes the record invalid if the filename already exists
        #
        # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
        #
        # === Note
        #
        # Set this key in your translations file for I18n:
        #
        #     carrierwave_direct:
        #       errors:
        #         filename_taken: 'Here be an error message'
        #
        def validates_filename_uniqueness_of(*attr_names)
          validates_with UniqueFilenameValidator, _merge_attributes(attr_names)
        end

        def validates_filename_format_of(*attr_names)
          validates_with FilenameFormatValidator, _merge_attributes(attr_names)
        end

        def validates_remote_net_url_format_of(*attr_names)
          validates_with RemoteNetUrlFormatValidator, _merge_attributes(attr_names)
        end

        def validates_is_uploaded(*attr_names)
          validates_with IsUploadedValidator, _merge_attributes(attr_names)
        end

        def validates_is_attached(*attr_names)
          validates_with IsAttachedValidator, _merge_attributes(attr_names)
        end

      end

      included do
        extend HelperMethods
        include HelperMethods
      end
    end
  end
end

Dir[File.dirname(__FILE__) << "/../locale/*.*"].each {|file| I18n.load_path << file }
