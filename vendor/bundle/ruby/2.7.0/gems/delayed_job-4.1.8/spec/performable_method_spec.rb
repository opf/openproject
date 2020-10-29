require 'helper'

describe Delayed::PerformableMethod do
  describe 'perform' do
    before do
      @method = Delayed::PerformableMethod.new('foo', :count, ['o'])
    end

    context 'with the persisted record cannot be found' do
      before do
        @method.object = nil
      end

      it 'does nothing if object is nil' do
        expect { @method.perform }.not_to raise_error
      end
    end

    it 'calls the method on the object' do
      expect(@method.object).to receive(:count).with('o')
      @method.perform
    end
  end

  it "raises a NoMethodError if target method doesn't exist" do
    expect do
      Delayed::PerformableMethod.new(Object, :method_that_does_not_exist, [])
    end.to raise_error(NoMethodError)
  end

  it 'does not raise NoMethodError if target method is private' do
    clazz = Class.new do
      def private_method; end
      private :private_method
    end
    expect { Delayed::PerformableMethod.new(clazz.new, :private_method, []) }.not_to raise_error
  end

  describe 'display_name' do
    it 'returns class_name#method_name for instance methods' do
      expect(Delayed::PerformableMethod.new('foo', :count, ['o']).display_name).to eq('String#count')
    end

    it 'returns class_name.method_name for class methods' do
      expect(Delayed::PerformableMethod.new(Class, :inspect, []).display_name).to eq('Class.inspect')
    end
  end

  describe 'hooks' do
    %w[before after success].each do |hook|
      it "delegates #{hook} hook to object" do
        story = Story.create
        job = story.delay.tell

        expect(story).to receive(hook).with(job)
        job.invoke_job
      end
    end

    it 'delegates enqueue hook to object' do
      story = Story.create
      expect(story).to receive(:enqueue).with(an_instance_of(Delayed::Job))
      story.delay.tell
    end

    it 'delegates error hook to object' do
      story = Story.create
      expect(story).to receive(:error).with(an_instance_of(Delayed::Job), an_instance_of(RuntimeError))
      expect(story).to receive(:tell).and_raise(RuntimeError)
      expect { story.delay.tell.invoke_job }.to raise_error(RuntimeError)
    end

    it 'delegates failure hook to object' do
      method = Delayed::PerformableMethod.new('object', :size, [])
      expect(method.object).to receive(:failure)
      method.failure
    end

    context 'with delay_job == false' do
      before do
        Delayed::Worker.delay_jobs = false
      end

      after do
        Delayed::Worker.delay_jobs = true
      end

      %w[before after success].each do |hook|
        it "delegates #{hook} hook to object" do
          story = Story.create
          expect(story).to receive(hook).with(an_instance_of(Delayed::Job))
          story.delay.tell
        end
      end

      it 'delegates error hook to object' do
        story = Story.create
        expect(story).to receive(:error).with(an_instance_of(Delayed::Job), an_instance_of(RuntimeError))
        expect(story).to receive(:tell).and_raise(RuntimeError)
        expect { story.delay.tell }.to raise_error(RuntimeError)
      end

      it 'delegates failure hook to object' do
        method = Delayed::PerformableMethod.new('object', :size, [])
        expect(method.object).to receive(:failure)
        method.failure
      end
    end
  end
end
