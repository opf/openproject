class Project
  def self.mock!(options = {})
    time = Time.now
    options = options.reverse_merge({:created_on => time,
                                     :identifier => "#{Project.all.size}project#{time.to_i}"[0..19],
                                     :name => "Project#{Project.all.size}"})
    generate! options
  end
end