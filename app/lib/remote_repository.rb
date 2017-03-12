require 'fileutils'
require 'git'

# Clones and keeps up to date a remote repository
class RemoteRepository
  # Get repo by name based on jarvis config
  # @param options [Hash]
  #   :command_runner the runner to report any command executed.
  # def self.get(name, options = {})
  def self.get(project, options = {})
    # config = Config.remote_repositories_config
    # repo_options = config[name.to_s].symbolize_keys.merge(
    #   base_path: config['base_path'],
    #   name: name.to_s
    # ).merge(options)

    new(project, options)
  end

  def initialize(project, options = {})
    @project = project
    @url = project.github_repo_url
    @options = options
  end

  def path
    @path ||= Rails.root.join(@project.base_path, name)
  end

  def name
    @options[:name] || @url.split('/').last.gsub(/\.git$/, '')
  end

  def setup_command
    @project.setup_command
    #@options[:setup_command]
  end

  # Initializes and updates the repository
  def update
    init_repository
    on_path do
      # Lock to not update repository simultaneously
      # with_lock do

      git.branch('master').checkout
      git.remote('origin').fetch
      git.reset_hard 'origin/master'

      # run_setup_command
      # end
    end
  end

  def init_repository
    # Folder
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless File.exist? dir

    # Repository
    return if File.exist? path

    #with_lock do
    return if File.exist? path # Somebody created the repo before you

    Rails.logger.info "Cloning repository #{@url}"
    Git.clone(@url, name, { path: File.dirname(path), branch: 'master' })
    #end
  end

  def on_path
    Dir.chdir(path) do
      yield
    end
  end

  def git
    @git ||= Git.open path
  end

  def with_lock
    Jarvis::Locker.new.lock_until("remote_repository:#{name}:lock") do
      yield
    end
  end

  def run_setup_command
    return unless setup_command

    failed = false
    runner = build_command_runner(on_failure: -> { failed = true })
    runner.run("cd #{path} && #{setup_command}")

    fail "Failed setup command #{setup_command}" if failed
  end

  # Gets io config from original command runner to send output there.
  def build_command_runner(options = {})
    base_options = @options[:command_runner].try(:io_options) || {}
    options = base_options.merge(options)
    Jarvis::CommandRunner.new(options)
  end
end
