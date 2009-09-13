module TestHelper
  def self.report_location(path)
    [RAILS_ROOT + '/', 'vendor/plugins/'].each { |part| path.sub! part, ''}
    path = path.split('/')
    location, subject = path.first, path.last
    if subject.sub! '.rb', ''
      subject = subject.classify
    else 
      subject.sub! '.html.erb', ''
    end
    "#{subject} (from #{location})"
  end
  
  def self.view_path_for path
    [RAILS_ROOT + '/', 'vendor/plugins/', '.html.erb'].each { |part| path.sub! part, ''}
    parts = path.split('/')
    parts[(parts.index('views')+1)..-1].join('/')
  end
end

class Test::Unit::TestCase
  # Add more helper methods to be used by all tests here...  
  def get_action_on_controller(*args)
    action = args.shift
    with_controller *args
    get action
  end
  
  def with_controller(controller, namespace = nil)
    classname = controller.to_s.classify + 'Controller'
    classname = namespace.to_s.classify + '::' + classname unless namespace.nil?
    @controller = classname.constantize.new
  end
  
  def assert_response_body(expected)
    assert_equal expected, @response.body
  end
end

# Because we're testing this behaviour, we actually want these features on!
Engines.disable_application_view_loading = false
Engines.disable_application_code_loading = false
