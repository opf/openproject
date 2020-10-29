module OkComputer
  class Engine < ::Rails::Engine
    isolate_namespace OkComputer

    config.after_initialize do |app|
      if OkComputer.mount_at
        app.routes.prepend do
          mount OkComputer::Engine => OkComputer.mount_at, as: "okcomputer"
        end
      end
    end
  end
end
