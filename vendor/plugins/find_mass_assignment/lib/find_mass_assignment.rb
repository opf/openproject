require 'active_support'  

# Find potential mass assignment problems.
# The method is to scan the controllers for likely mass assignment,
# and then find the corresponding models that *don't* have 
# attr_accessible defined.  Any time that happens, it's a potential problem.

class String
  
  @@cache = {}
  
  # A regex to match likely cases of mass assignment
  # Examples of matching strings:
  #   "Foo.new( { :bar => 'baz' } )"
  #   "Foo.update_attributes!(params[:foo])"
  MASS_ASSIGNMENT = /(\w+)\.(new|create|update_attributes|build)!*\(/
  
  # Return the strings that represent potential mass assignment problems.
  # The MASS_ASSIGNMENT regex returns, e.g., ['Post', 'new'] because of
  # the grouping methods; we want the first of the two for each match.
  # For example, the call to scan might return
  #   [['Post', 'new'], ['User', 'create']]
  # We then select the first element of each subarray, returning
  #   ['Post', 'User']
  # Finally, we call classify to turn the string into a class.
  def mass_assignment_models
    scan(MASS_ASSIGNMENT).map { |problem| problem.first.classify }
  end

  # Return true if the string has potential mass assignment code.
  def mass_assignment?
    self =~ MASS_ASSIGNMENT
  end
  
  # Return true if the model defines attr_accessible.
  # Note that 'attr_accessible' must be preceded by nothing other than
  # whitespace; this catches cases where attr_accessible is commented out.
  def attr_accessible?
    model = "#{Rails.root}/app/models/#{self.underscore}.rb"
    if File.exist?(model)
      return @@cache[model] unless @@cache[model].nil?
      @@cache[model] = File.open(model).read =~ /^\s*attr_accessible/
    else
      # If the model file doesn't exist, ignore it by returning true.
      # This way, problem? is false and the item won't be flagged.
      true
    end
  end
  
  # Return true if a model does not define attr_accessible.
  def problem?
    !attr_accessible?
  end
  
  # Return true if a line has a problem model (no attr_accessible).
  def problem_model?
    problem = mass_assignment_models.find { |model| model.problem? }
    !problem.nil?
  end
  
  # Return true if a controller string has a (likely) mass assignment problem.
  # This is true if at least one of the controller's lines 
  #   (1) Has a likely mass assignment
  #   (2) The corresponding model doesn't define attr_accessible
  def mass_assignment_problem?
    c = File.open(self)
    problem = c.find { |line| line.mass_assignment?  }
    !problem.nil?
  end
end

module MassAssignment

  def self.print_mass_assignment_problems(controller)
    lines = File.open(controller)
    lines.each_with_index do |line, number|
      if line.mass_assignment? 
        puts "    #{number + 1}  #{line}"
      end
    end
  end

  # Find and output mass assignment problems.
  # Exit with non-zero status on error for use in pre-commit hooks.
  # E.g., put 'rake find_mass_assignment' at the end of .git/hooks/pre-commit
  # and then run
  # $ chmod +x git/hooks/pre-commit
  def self.find
    exit_status = 0
    
    # all core controllers
    controllers  = Dir.glob("#{Rails.root}/app/controllers/**/*controller*.rb")
    # all plugin controllers and controller_patches
    controllers += Dir.glob("#{Rails.root}/../plugins/**/*controller*.rb")
    # minus all controller specs
    controllers -= Dir.glob("#{Rails.root}/../plugins/**/*_spec.rb")
    
    controllers.each do |controller|
      if controller.mass_assignment_problem?
        puts "\n#{controller}"
        print_mass_assignment_problems(controller)
        exit_status = 1
      end
    end
  ensure
    Process.exit exit_status
  end
end
