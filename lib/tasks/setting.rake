namespace :setting do
  desc 'Allow to set a Setting: rake setting:set[key1=value1,key2=value2]'
  task set: :environment do |_t, args|
    args.extras.each do |tuple|
      key, value = tuple.split('=')
      setting = Setting.find_by_name(key)
      if setting.nil?
        Setting.create! name: key, value: value
      else
        setting.update_attributes! value: value
      end
    end
  end

  desc 'Allow to get a Setting: rake setting:get[key]'
  task :get, [:key] => :environment do |_t, args|
    setting = Setting.find_by_name(args[:key])
    unless setting.nil?
      puts(setting.value)
    end
  end
end
