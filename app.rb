require 'bundler/setup'

require 'celluloid/autostart'
require 'logger'
require 'haml'
require 'sinatra/base'

LOGGER = Logger.new($stdout)
LOGGER.progname = 'cellfun'

class Counter
  include Celluloid
  include Celluloid::Notifications

  attr_reader :count

  def initialize
    @count = 0
  end

  def increment
    exclusive { @count += 1 }
    LOGGER.info "Count is now #{@count}"
    publish('message', "Count is now #{@count}")
  end
end

class Subscriber
  include Celluloid
  include Celluloid::Notifications
  finalizer :finalizer
  exclusive :add_stream, :del_stream

  def initialize
    @ios = []
    subscribe(/message/, :receive)
  end

  def handle(stream)
    io = stream
    send_headers(io)
    add_stream(io)
  end

  def send_headers(io)
    io << "HTTP 200 OK\r\n"
    io << "Content-Type: text/event-stream\r\n"
    io << "Transfer-Encoding: identity\r\n"
    io << "Cache-Control: no-cache\r\n"
    io << "\r\n"
    io.flush
  end

  def receive(event, payload)
    LOGGER.info("current: #{current_actor}, streams: #{@ios.count}, event: #{event}, data: #{payload}")
    @ios.each do |io|
      begin
        raise SocketError, "Closed" if io.closed?
        io << "event: #{event}\n"
        io << "data: Stream #{io.object_id}: #{payload}\n\n"
        io.flush
      rescue => x
        LOGGER.info("stream: #{io.object_id} is dead: #{x.message}")
        del_stream(io)
      end
    end
  end

  def add_stream(io)
    LOGGER.info("new stream added #{io.object_id}, streams: #{@ios.count}")
    @ios << io
  end

  def del_stream(io)
    @ios.delete io
  end

  def finalizer
    LOGGER.info("[finalizer] streams: #{@ios.count}")
    ios.each do |io|
      io.close unless io.closed? rescue nil
    end
    unsubscribe self
  end
end

class Server < Sinatra::Base
  Celluloid::Actor[:counter] = Counter.new
  Celluloid::Actor[:subscriber_pool] = Subscriber.new

  configure do
    set :app_file, __FILE__
    set :logging, false
    set :dump_errors, false
    set :run, false
    set :server, 'puma'
    set :bind, '0.0.0.0'
    set :port, 3000
    set :public_folder, File.expand_path('../static', __FILE__)
  end

  helpers do
    def counter
      Celluloid::Actor[:counter]
    end

    def subscriber_pool
      Celluloid::Actor[:subscriber_pool]
    end
  end

  get '/increment/?' do
    by = (params[:by] || 1).to_i
    by.times { counter.async.increment }
    "[Count] currently: #{counter.count.to_s}"
  end

  get '/stream' do
    io = env['rack.hijack'].call
    subscriber_pool.async.handle(io)
    #Subscriber.new.async.handle(io)
  end

  get '/pool' do
    "[Subscriber Pool] busy: #{subscriber_pool.busy_size}, idle: #{subscriber_pool.idle_size}"
  end

  get '/' do
    haml :index
  end
end

if $0 == __FILE__
  app = Server
  app.run!
end
