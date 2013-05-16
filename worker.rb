require 'redis'

redis = Redis.new
i = 0
loop do
	redis.lpush('incoming_messages', "#{i}")
	i += 1
	sleep(5/1000.0)
end
