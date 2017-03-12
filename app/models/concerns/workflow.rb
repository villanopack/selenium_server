module Workflow
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm do
      state :waiting, initial: true
      state :deploying
      state :running_tests
      state :tests_success
      state :tests_failed
      state :finished

      event :start, after: proc { do_deploy } do
        transitions from: :waiting, to: :running_tests
      end

      event :success, after: proc { do_success } do
        transitions from: :running_tests, to: :tests_success, after: :update_github
      end

      event :failure, after: proc { do_fail } do
        transitions from: :running_tests, to: :tests_failed, after: :update_github
        transitions from: :deploying, to: :tests_failed, after: :update_github
      end

      event :finish, after: proc { close } do
        transitions from: :tests_success, to: :finished, after: :close
        transitions from: :tests_failed, to: :finished, after: :close
      end
    end
  end

  def do_deploy
    Rails.logger.info('starting deploy')
  end

  def do_success
    byebug
    Rails.logger.info('Test success')
    self.finish!
  end

  def do_fail
    Rails.logger.info('Test failed')
  end

  def close
    Rails.logger.info('closing the test')
  end
end
