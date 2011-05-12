require 'mongo/rails/instrumentation'

module Mongo::Rails::Instrumentation
  class Railtie < Rails::Railtie
    initializer "mongo.rails.instrumentation" do |app|
      instrument Mongo::Connection, [
                                     :send_message,
                                     :send_message_with_safe_check,
                                     :receive_message
                                    ], "mongo"

      instrument Mongo::Cursor, [
                                 :initialize
                                ], "query"

      ActiveSupport.on_load(:action_controller) do
        include ControllerRuntime
      end

      LogSubscriber.attach_to :mongo
    end

    def instrument(clazz, methods, name)
      clazz.module_eval do
        methods.each do |m|
          class_eval %{def #{m}_with_instrumentation(*args, &block)
            ActiveSupport::Notifications.instrumenter.instrument "#{name}.mongo", :name => "#{m}", :cursor => args do
              #{m}_without_instrumentation(*args, &block)
            end
          end
          }

          alias_method_chain m, :instrumentation
        end
      end
    end
  end
end
