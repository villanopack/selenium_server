class TestJob
  attr_reader :runner, :test

  def initialize(id)
    @test = Test.find(id)
    @test.output = ''
  end

  def self.queue
    :tests
  end

  def self.perform(*args)
    new(*args).perform
  end

  def perform
    prepare_runner
    prepare_environment
    runner.run('cd /Users/villanopack/Wuaki/kraken && ./integration-test.sh')
  end

  def prepare_runner
    @runner = CommandRunner.new(
      append_output: lambda do |str|
        ActionCable.server.broadcast 'tests', output: str
        test.output += str
      end,
      on_failure: -> { test.failure! },
      on_running: -> { test.start! },
      on_success: -> { test.success! }
    )
  end

  def prepare_environment
    RemoteRepository.get(test.project).update
  end
end
