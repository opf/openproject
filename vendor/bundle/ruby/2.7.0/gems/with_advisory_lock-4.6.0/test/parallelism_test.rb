require 'minitest_helper'
require 'forwardable'

describe 'parallelism' do
  class FindOrCreateWorker
    extend Forwardable
    def_delegators :@thread, :join, :wakeup, :status, :to_s

    def initialize(name, use_advisory_lock)
      @name = name
      @use_advisory_lock = use_advisory_lock
      @thread = Thread.new { work_later }
    end

    def work_later
      sleep
      ActiveRecord::Base.connection_pool.with_connection do
        if @use_advisory_lock
          Tag.with_advisory_lock(@name) { work }
        else
          work
        end
      end
    end

    def work
      Tag.transaction do
        Tag.where(name: @name).first_or_create
      end
    end
  end

  def run_workers
    @names = @iterations.times.map { |iter| "iteration ##{iter}" }
    @names.each do |name|
      workers = @workers.times.map do
        FindOrCreateWorker.new(name, @use_advisory_lock)
      end
      # Wait for all the threads to get ready:
      until workers.all? { |ea| ea.status == 'sleep' }
        sleep(0.1)
      end
      # OK, GO!
      workers.each(&:wakeup)
      # Then wait for them to finish:
      workers.each(&:join)
    end
    # Ensure we're still connected:
    ActiveRecord::Base.connection_pool.connection
  end

  before :each do
    ActiveRecord::Base.connection.reconnect!
    @workers = 10
  end

  # < SQLite, understandably, throws "The database file is locked (database is locked)"

  it 'creates multiple duplicate rows without advisory locks' do
    skip if env_db == :sqlite
    @use_advisory_lock = false
    @iterations = 1
    run_workers
    Tag.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    TagAudit.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    Label.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
  end

  it "doesn't create multiple duplicate rows with advisory locks" do
    @use_advisory_lock = true
    @iterations = 10
    run_workers
    Tag.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    TagAudit.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    Label.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
  end
end
