Subscribem.configure do |c|
  c.attachment_class     = 'Attachment'.constantize # todo
  c.default_data_loader  = lambda { Redmine::DefaultData::Loader.load }
  c.settings_class       = 'Setting'.constantize # todo
  c.tld_length           = ENV.fetch('TLD_LENGTH', 1).to_i
end
