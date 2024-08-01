module Autocad
  class EventHandler
    def initialize
      @handlers = {}
      @file = File.open("event_handler.log", "w")
    end

    def add_handler(event, &block)
      @handlers[event] = block if block
    end

    def get_handler(event)
      @handlers[event]
    end

    def method_missing(event, *args)
      if @handlers[event.to_s]
        @handlers[event.to_s].call(*args)
      else
        @file.puts "Unhandled event: #{event} args: #{args}"
        @file.puts "Event class is: #{event.class}, args are: #{args}"
        # event = event.to_sym if event.is_a? String
        # super
      end
    end
  end
end
