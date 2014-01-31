class MessagesController < ApplicationController
  include ActionController::Live
  
  def index
    @messages = Message.all
  end
  
  def create
    response.headers["Content-Type"] = "text/javascript"
    attrs = params.require(:message).permit(:content, :name, :connection_id)
    @message = Message.create!(attrs)
    $redis.publish('messages.create', @message.to_json)
  end
  
  def events
    start = Time.zone.now
    redis = Redis.new
    redis.subscribe('messages.create') do |on|
      response.headers["Content-Type"] = "text/event-stream"
      on.message do |event, data|
        response.stream.write("data: #{data}\n\n")
      end
    end
  rescue IOError
  ensure
    redis.quit
    response.stream.close
  end  
  
end
