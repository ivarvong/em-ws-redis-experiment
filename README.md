An experiment with Ruby, EventMachine, WebSockets and Redis
===

Basic idea: use Redis lists as queues. Taking incoming sources, and LPUSH them onto a list. Use em-hiredis/BRPOP to grab stuff off the other end. 

Next up:

- Something like JSON-RPC on WebSockets (another queue for processing)
- Persist incoming objects to Postgres. This is where the queues should be awesome.
- Use Fibers to clean stuff up a bit. em-synchrony confused me a lot, so, maybe more reading.
- Sessions/etc
- AngularJS



