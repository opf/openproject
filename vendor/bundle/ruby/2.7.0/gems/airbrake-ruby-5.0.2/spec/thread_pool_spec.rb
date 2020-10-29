RSpec.describe Airbrake::ThreadPool do
  let(:tasks) { [] }
  let(:worker_size) { 1 }
  let(:queue_size) { 2 }

  subject do
    described_class.new(
      worker_size: worker_size,
      queue_size: queue_size,
      block: proc { |message| tasks << message },
    )
  end

  describe "#<<" do
    it "returns true" do
      retval = subject << 1
      subject.close
      expect(retval).to eq(true)
    end

    it "performs work in background" do
      subject << 2
      subject << 1
      subject.close

      expect(tasks).to eq([2, 1])
    end

    context "when the queue is full" do
      before do
        allow(subject).to receive(:backlog).and_return(queue_size)
      end

      subject do
        described_class.new(
          worker_size: 1,
          queue_size: 1,
          block: proc { |message| tasks << message },
        )
      end

      it "returns false" do
        retval = subject << 1
        subject.close
        expect(retval).to eq(false)
      end

      it "discards tasks" do
        200.times { subject << 1 }
        subject.close

        expect(tasks.size).to be_zero
      end

      it "logs discarded tasks" do
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /reached its capacity/,
        ).exactly(15).times

        15.times { subject << 1 }
        subject.close
      end
    end
  end

  describe "#backlog" do
    let(:worker_size) { 0 }

    it "returns the size of the queue" do
      subject << 1
      expect(subject.backlog).to eq(1)
    end
  end

  describe "#has_workers?" do
    it "returns false when the thread pool is not closed, but has 0 workers" do
      subject.workers.list.each do |worker|
        worker.kill.join
      end
      expect(subject).not_to have_workers
    end

    it "returns false when the thread pool is closed" do
      subject.close
      expect(subject).not_to have_workers
    end

    describe "forking behavior" do
      before do
        skip('fork() is unsupported on JRuby') if %w[jruby].include?(RUBY_ENGINE)
        unless Process.respond_to?(:last_status)
          skip('Process.last_status is unsupported on this Ruby')
        end
      end

      it "respawns workers on fork()" do
        pid = fork { expect(subject).to have_workers }
        Process.wait(pid)
        subject.close

        expect(Process.last_status).to be_success
        expect(subject).not_to have_workers
      end

      it "ensures that a new thread group is created per process" do
        subject << 1
        pid = fork { subject.has_workers? }
        Process.wait(pid)
        subject.close

        expect(Process.last_status).to be_success
      end
    end
  end

  describe "#close" do
    context "when there's no work to do" do
      it "joins the spawned thread" do
        workers = subject.workers.list
        expect(workers).to all(be_alive)

        subject.close
        expect(workers).to all(be_stop)
      end
    end

    context "when there's some work to do" do
      it "logs how many tasks are left to process" do
        thread_pool = described_class.new(
          worker_size: 0, queue_size: 2, block: proc {},
        )

        expect(Airbrake::Loggable.instance).to receive(:debug).with(
          /waiting to process \d+ task\(s\)/,
        )
        expect(Airbrake::Loggable.instance).to receive(:debug).with(/closed/)

        2.times { thread_pool << 1 }
        thread_pool.close
      end

      it "waits until the queue gets empty" do
        thread_pool = described_class.new(
          worker_size: 1, queue_size: 2, block: proc {},
        )

        10.times { subject << 1 }
        thread_pool.close
        expect(thread_pool.backlog).to be_zero
      end
    end

    context "when it was already closed" do
      it "doesn't increase the queue size" do
        begin
          subject.close
        rescue Airbrake::Error
          nil
        end

        expect(subject.backlog).to be_zero
      end

      it "raises error" do
        subject.close
        expect { subject.close }.to raise_error(
          Airbrake::Error, 'this thread pool is closed already'
        )
      end
    end
  end

  describe "#spawn_workers" do
    it "spawns alive threads in an enclosed ThreadGroup" do
      expect(subject.workers).to be_a(ThreadGroup)
      expect(subject.workers.list).to all(be_alive)
      expect(subject.workers).to be_enclosed

      subject.close
    end

    it "spawns exactly `workers_size` workers" do
      expect(subject.workers.list.size).to eq(worker_size)
      subject.close
    end
  end
end
