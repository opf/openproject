class TaskList

  def self.root_path
    @root_path ||= Pathname.new(File.expand_path("../../../", __FILE__))
  end

  def self.asset_paths
    @paths ||= Dir[root_path.join("app/assets/*")]
  end

  if defined? ::Rails::Railtie
    class Railtie < ::Rails::Railtie
      initializer "task_list" do |app|
        TaskList.asset_paths.each do |path|
          app.config.assets.paths << path
        end
      end
    end
  end
end
