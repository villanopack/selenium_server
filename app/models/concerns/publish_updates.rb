module PublishUpdates
  extend ActiveSupport::Concern

  included do
    after_save :publish_to_redis, on: :update
  end

  protected

  def publish_to_redis
    Jarvis.redis.publish "update:#{self.class.base_class.to_s.tableize}",
                         decorate.to_update_callback
  end
end
