# encoding: utf-8

require 'action_view'
require 'action_view/template'
require 'action_controller'
require 'active_model'

require File.join(File.dirname(__FILE__), 'view_helpers')

require 'carrierwave_direct/form_builder'
require 'carrierwave_direct/action_view_extensions/form_helper'

module FormBuilderHelpers
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include CarrierWaveDirect::ActionViewExtensions::FormHelper
  include ActionView::Context

  # Try ActionView::RecrodIentifier for Rails 4
  # else use ActionController::RecordIdentifier for Rails 3.2
  begin
    include ActionView::RecordIdentifier
  rescue
    include ActionController::RecordIdentifier
  end

  include ::ViewHelpers

  def direct_uploader
    defined?(super) ? super : @direct_uploader ||= MountedClass.new.video
  end

  def self.included(base)
    DirectUploader.send(:include, ActiveModel::Conversion)
    DirectUploader.extend ActiveModel::Naming
  end

  def protect_against_forgery?
    false
  end

  def form(options = {}, &block)
    blk = block_given? ? block : Proc.new {|f|}
    direct_upload_form_for(direct_uploader, options, &blk)
  end
end
