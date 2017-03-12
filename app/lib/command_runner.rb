require 'pty'
require 'timeout'

# Abstracts the call to a console command to extract it's output
class CommandRunner
  include Timeout

  attr_reader :options, :command_env

  # @param options [Hash]
  #   :on_failure the block to call when the command has falied.
  #   :on_running block that will be called when the running has started.
  #   :append_output block that receives chunks of strings to send to
  #     consumers
  #   :update_pid block that receives the pid of the process that is running
  #     the command.
  #   :stdout standard output IO. Default $stdout
  #   :timeout the time between outputs expected. If the taks lasts longer,
  #     a message appears in the output notifying that its been slow. BUT the
  #     job is never stopped. Default: 60 sec
  #   :command_env the env variables that needs this command.
  def initialize(options = {})
    @options = self.class.default_options.merge(options)
  end

  def self.default_options
    {
      stdout: $stdout,
      timeout: 60.seconds
    }.freeze
  end

  # Returns io options to forward to other commands
  def io_options
    options.select { |k, _| [:append_output, :stdout].include? k }
  end

  def run(command)
    append_output "Running command: #{command} \n"
    running!
    #Bundler.with_clean_env do // Not necessary because so far we are not running
    # commands that have to be executed using the bundler context
    spawn_process(command)
    #end
  rescue PTY::ChildExited => e
    puts "Exited: #{e.status}"
  rescue => exception
    puts "Exception #{exception}"
    failed!
    save_exception(exception)
  else
    $CHILD_STATUS.success? ? success! : failed!
  end

  def spawn_process(command)
    PTY.spawn(command_env, command) do |output, _, pid|
      #update_pid(pid)
      begin
        handle_output(output)
      rescue Errno::EIO
        nil
      ensure
        Process.wait(pid)
      end
    end
  end

  # Called with new deltas
  def append_output(str)
    options[:stdout].write str
    options[:append_output].try(:call, str)
  end

  def failed!
    options[:on_failure].try(:call)
  end

  def running!
    options[:on_running].try(:call)
  end

  def success!
    options[:on_success].try(:call)
  end

  def update_pid(pid)
    options[:update_pid].try(:call, pid)
  end

  def handle_output(output)
    timeout(options[:timeout]) do
      loop do
        buffer = output.readpartial(1024)
        buffer.force_encoding(Encoding::UTF_8)
        append_output(buffer)
      end
    end
  rescue Timeout::Error
    append_output I18n.t('command_timeout')
    retry
  rescue EOFError
    append_output '\n *** Commmand finished'
    nil
  end

  def save_exception(exception)
    append_output "\n #{exception.class}: #{exception.message}\n"
    append_output exception.backtrace.join("\n")
    options[:on_exception].try(:call, exception)
  end

  # Generates a hash with all env vars that will be used in the command
  def command_env
    env_without_bundler(ENV).merge('PATH' => new_path_var(ENV))
      .merge(options.fetch(:command_env, {}))
  end

  # We need to override some of the current environment variables
  # set by rbenv
  def env_without_bundler(env)
    re = /\ABUNDLE|RBENV|GEM/

    bundler_keys = env.select { |var, _| var.to_s.match(re) }.keys
    bundler_keys.reduce({}) do |hash, (k, _)|
      hash[k] = nil
      hash
    end
  end

  # rbenv was not working properly when the process is spawned.
  # Because the PATH is already set to work with the current ruby,
  # we need to remove the ruby related PATH segments.
  #
  # This is taken from https://github.com/sstephenson/rbenv/issues/121
  def new_path_var(env)
    rbenv_root = exec_rbenv_root
    return env['PATH'] if rbenv_root.empty?

    re = /^#{Regexp.escape rbenv_root}\/(versions|plugins|libexec)\b/
    paths = env['PATH'].split(':')
    paths.reject! { |p| p =~ re }

    paths.join(':')
  end

  def exec_rbenv_root
    @rbenv_root ||= `rbenv root 2>/dev/null`.chomp
  end
end
