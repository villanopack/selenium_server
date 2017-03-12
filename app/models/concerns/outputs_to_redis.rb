module OutputsToRedis
  extend ActiveSupport::Concern

  def output=(output_data)
    Config.redis.publish append_channel,
                         delta_to_publish(output_data)
    Config.redis.set output_id, output_data
  end

  def output
    Config.redis.get(output_id) || ''
  end

  protected

  # +output+ can be empty of only blank data. In the case it is only
  # blank space we want it to be published.
  def output_delta(output_data)
    if output.present?
      output_data.gsub(output, "\n")
    else
      output
    end
  end

  def delta_to_publish(output_data)
    decorate.to_append_callback(decorate.html_output(output_delta(output_data)))
  end

  def output_id
    "tests:#{self.class.base_class.to_s.tableize}:#{self.id}"
  end

  def update_channel
    "update:#{self.class.base_class.to_s.tableize}"
  end

  def append_channel
    "append:#{self.class.base_class.to_s.tableize}"
  end
end
