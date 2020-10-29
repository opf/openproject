# Sadly, we have to monkeypatch Rake because all of the Rails database tasks are
# hardcoded for specific adapters, with no extension points (!)
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

def wrap_task(task_name, &wrapper)
  wrapped_task = Rake::Task[task_name]
  remove_task(Rake::Task.scope_name(Rake.application.current_scope,
                                    task_name))
  task(task_name) do
    wrapper.call(wrapped_task)
  end
end

namespace :db do
  namespace :test do
    wrap_task :purge do |wrapped_task|
      if ActiveRecord::Base.configurations["test"]["adapter"] == "nulldb"
        # NO-OP
      else
        wrapped_task.invoke
      end
    end
  end
end
