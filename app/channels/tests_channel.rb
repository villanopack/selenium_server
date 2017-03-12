class TestsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'tests'
  end
end
