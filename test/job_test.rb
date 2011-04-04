require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class JobTest < Test::Unit::TestCase

  def setup
    Resque::Plugins::PriorityQueue.enable!
  end

  class ::SomePriorityJob

    def self.after_enqueue_do_something(*args)
      @did_something = true
    end

    def self.perform(*args)
    end
  end


  def test_create_with_priority
    @worker = Resque::Worker.new(:priority_jobs)

    Resque::Job.create_with_priority(:priority_jobs, SomePriorityJob, 75)

    # we actually store 1000 minus the priority
    assert_equal "925", Resque.redis.zscore("queue:priority_jobs", Resque.encode(:class => 'SomePriorityJob', :args => []))

    @worker.work(0)

    assert ::SomePriorityJob.instance_variable_get(:@did_something)
  end

  def test_create_or_update_priority
    Resque::Job.create_or_update_priority(:priority_jobs, SomePriorityJob, 75)

    # we actually store 1000 minus the priority
    assert_equal "925", Resque.redis.zscore("queue:priority_jobs", Resque.encode(:class => 'SomePriorityJob', :args => []))

    Resque::Job.create_or_update_priority(:priority_jobs, SomePriorityJob, 975)
    # we store 1000 minus the priority
    assert_equal '25', Resque.redis.zscore("queue:priority_jobs", Resque.encode(:class => SomePriorityJob, :args => []))
  end

  def test_job_priority
    Resque::Job.create_with_priority(:priority_jobs, SomePriorityJob, 77, 'asdf', 'jkl;')

    assert_equal 77, Resque::Job.priority(:priority_jobs, SomePriorityJob, 'asdf', 'jkl;')
  end

end
