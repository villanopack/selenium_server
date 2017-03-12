class Test < ActiveRecord::Base
  belongs_to :project
  include Workflow
  paginates_per 10
end
