# Once a new project is added to jarvis this clones it, adds it as a
# project managed by anvil and creates the needed hooks on github.
class SetupProjectJob
  attr_reader :project_id, :user_id

  def initialize(project_id, user_id)
    @project_id = project_id
    @user_id = user_id
  end

  def self.queue
    'projects'
  end

  def self.perform(project_id, user_id)
    new(project_id, user_id).perform
  end

  def perform
    manage_project
    add_hooks
  end

  private

  def manage_project
    response = Projects::Manage.call(project)

    fail 'Failed adding project to jarvis' if response.failed?
  end

  def add_hooks
    response = Projects::AddHooks.call(project, current_user: user)

    fail 'Failed github hooks setup for project' if response.failed?
  end

  def project
    @project ||= Project.find project_id
  end

  def user
    @user = User.find(user_id)
  end
end
