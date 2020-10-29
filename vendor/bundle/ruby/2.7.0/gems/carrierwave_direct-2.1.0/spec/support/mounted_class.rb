# encoding: utf-8

require File.dirname(__FILE__) << "/direct_uploader"

class MountedClass
  extend CarrierWave::Mount
  extend CarrierWaveDirect::Mount
  mount_uploader :video, DirectUploader
end

