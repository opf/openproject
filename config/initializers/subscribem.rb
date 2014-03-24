Subscribem.configure do |c|
  c.attachment_class     = 'Attachment'
  c.default_data_loader  = lambda { Redmine::DefaultData::Loader.load }
  c.settings_class       = 'Setting'
  c.host                 = ENV.fetch('HOST_NAME')
end if defined? Subscribem
