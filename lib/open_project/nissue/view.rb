class OpenProject::Nissue::View
  unloadable

  include ActionView::Helpers
  include Redmine::I18n


  def self.inherited(sub)
    method = lambda do |subclass|
      subclass.class_eval do
        unloadable
      end
      subclass.instance_eval do
        define_method :inherited, &method
      end
    end

    method.call(sub)
    super
  end
end
