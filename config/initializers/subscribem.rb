Subscribem.configure do |c|
  c.attachment_class     = 'Attachment'
  c.default_data_loader  = lambda { Redmine::DefaultData::Loader.load }
  c.settings_class       = 'Setting'
  c.host                 = ENV.fetch('HOST_NAME') { 'openproject-demo.org' }
  c.excluded_domains     = ENV.fetch('SUBSCRIBEM_EXCLUDED_DOMAINS',
                                     'localhost openproject.dev').split(' ')
end if defined? Subscribem
