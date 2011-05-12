require 'mongo/rails/instrumentation'

class Mongo::Rails::Instrumentation::LogSubscriber < ActiveSupport::LogSubscriber
  def self.runtime=(value)
    Thread.current["mongo_mongo_runtime"] = value
  end

  def self.runtime
    Thread.current["mongo_mongo_runtime"] ||= 0
  end

  def self.reset_runtime
    rt, self.runtime = runtime, 0
    rt
  end

  def initialize
    super

    @odd_or_even = false
  end

  def mongo(event)
    self.class.runtime += event.duration
  end

  def query(event)
    return unless logger.debug?

    collection, options = event.payload[:cursor]

    name = "MONGO QUERY"

    query = format_query options.delete(:selector)
    extra = format_query options

    debug "  #{color(name, YELLOW, true)} #{collection.name} { #{query} } [ #{extra} ]"
  end

  # produces: 'query: "foo" OR "bar", rows: 3, ...'
  def format_query(query)
    query.map{ |k, v| "#{k}: #{color(v, BOLD, true)}" if v.present? }.compact.join(', ')
  end

  def odd?
    @odd_or_even = !@odd_or_even
  end

  def logger
    Rails.logger
  end
end
