# encoding: utf-8

require File.dirname(__FILE__) << "/mounted_class"

module UploaderHelpers
  include CarrierWaveDirect::Test::Helpers

  def sample_key(options = {})
    super(MountedClass.new.video, options)
  end
end

