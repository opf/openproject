module Shindo
  class Tests
    def succeeds
      test('succeeds') do
        !instance_eval(&Proc.new).nil?
      end
    end
  end
end
