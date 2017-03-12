# Basic config and initializers.
require 'uri'

module Config
  def self.redis
    Redis::Namespace.new('tests', redis: redis_instance)
  end

  def self.redis_instance
    define_redis
  end

  def self.define_redis
    redis = Redis.new(redis_config)
    redis.client.logger = Rails.logger
    redis
  end

  def self.lock_manager
    @lock_manager ||= Redlock::Client.new([redis_url.presence])
  end

  def self.init_resque
    Resque.redis = Redis::Namespace.new('tests:resque', redis_instance)
  end

  def self.remote_repositories_config
    SeleniumServer::Application.config_for(:remote_repositories)
  end

  def self.config
    SeleniumServer::Application.config_for(:jarvis)
  end

  protected

  def self.redis_config
    {
      url: redis_url,
      timeout: 25
    }
  rescue Errno::ENOENT
    {}
  end

  # Returns a redis URL string with schema read from config
  def self.redis_url
    url = SeleniumServer::Application.config_for(:redis)

    return unless url.present?

    parsed_url = URI(url)

    return parsed_url.to_s if parsed_url.host

    # Sometimes the url comes without protocol.
    "redis://#{url}"
  end
end
