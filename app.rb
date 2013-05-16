require 'json'
require 'sinatra/base'
require 'sinatra-websocket'
require "rack/fiber_pool"

require 'em-hiredis'

require 'thin'

class App < Sinatra::Base
    use Rack::FiberPool
    use Rack::CommonLogger

    def initialize
        super
        @sockets = []               

        @redis = EM::Hiredis.connect #used for LPUSH and LLEN
        @redis_block = EM::Hiredis.connect #used with BRPOP to watch the queue list
        @pubsub = @redis.pubsub

        EventMachine.next_tick{ pop_message() } #set up BRPOP the first time

        @redis.pubsub.psubscribe("*") { |channel, message|          
            if channel == "broadcast"
                EventMachine.next_tick {
                    @sockets.each{|s| s.send "#{message}"}
                }           
            end 
        }

        timer = EventMachine::PeriodicTimer.new(2) do
            @redis.llen("incoming_messages"){|res|
                puts "LLEN: #{res}"
            }
        end
    end 

    get '/' do
        erb :index
    end

    get '/ws' do
        request.websocket do |ws|
            ws.onopen do
                @sockets << ws
                update_client_count()
            end
            ws.onclose do
                @sockets.delete ws
                update_client_count()
            end
            ws.onmessage do |msg|                                           
                @redis.lpush('incoming_messages', msg).callback{|res|
                    #all is well?
                }.errback{|res|
                    puts "ERROR! LPUSH-IN'" #? not tested.
                }               
            end
        end
    end

    def update_client_count
        broadcast({id: 'count', data: @sockets.count})
    end

    def pop_message
        @redis_block.brpop('incoming_messages', 0).callback{|key, message|
            puts "BRPOP grabbed: #{message} (on '#{key}')"              
            broadcast({id:'message', data:message})
            #EventMachine.add_timer(0.10) { # don't push to the client more than 10Hz
            EventMachine.next_tick{
                pop_message()
            }   
        }                   
    end
    
    def broadcast(message) 
        @redis.publish 'broadcast', "#{message.to_json}"
    end
    
end