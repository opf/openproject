require 'mixlib/shellout'

module RunCommand
  def run_command(command)
    shell = Mixlib::ShellOut.new(command)
    shell.run_command
    if shell.error? && !(shell.stdout =~ /nothing to commit/)
      raise "The following command returned an error: #{command}. Error message: #{shell.stderr}"
    end

    shell.stdout.gsub(/\n$/, '')
  end
end
