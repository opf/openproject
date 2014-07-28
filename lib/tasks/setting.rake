namespace :setting do
  desc "Allow to set a Setting: rake setting:set[key1=value1,key2=value2]"
  task :set => :environment do |t,args|
    args.extras.each do |tuple|
      key, value = tuple.split("=")
      setting = Setting.find_by_name(key)
      if setting.nil?
        Setting.create! name: key, value: value
      else
        setting.update_attributes! value: value
      end
    end
  end
end
