class EventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # if GitChecker.isMaster()
    if true
      test = Test.create(project_id: 1)
      Resque.enqueue(TestJob, test.id)
    else
      head(:not_found)
    end
  end
end
