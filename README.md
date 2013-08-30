Fun with Celluloid
==================

This is a sandbox for experimenting with augmenting existing Sinatra apps with Celluloid. 

In particular, this example detatches SSE sockets from Puma and hands them off to a pub/sub
style Celluloid messenger. Or something like that.

Full stack:

* [Celluloid](http://celluloid.io/) 0.14.1
* [Puma](http://puma.io) 2.5.1
* [Sinatra](http://www.sinatrarb.com/) 1.4.2
* [JRuby](http://jruby.org) 1.7.x
* [OpenJDK](http://openjdk.java.net/) 7

Other tools used:

* [EventSource Polyfill](https://github.com/Yaffle/EventSource) from Yaffle.
* [AngularJS](http://angularjs.org/) is overkill here but I like it. So there!

In action
---------
To see this in action:

```
$ bundle install --path=./vendor
$ bundle exec puma --port 3000
```

When the app starts up, point your browser to http://localhost:3000/. It should establish an
SSE connection at that point by hijacking the socket from Puma. Next, send a message from another
browser, or curl, or whatever you'd like with a GET request to http://localhost:3000/preent/<msg> 
where <msg> is any text you'd like to see presented.

Now attach as many browsers as you can find to listen. I've forked 200 curl processes to the SSE
route (http://localhost:3000/stream) while pumping messages with ab -n 1000 -c 50; all without any 
issues.

Note: 
-----

If this is interesting to you and you aren't locked into a legacy-ish application then you may
be more interested in looking at [Reel](https://github.com/celluloid/reel) which is a standalone 
web application framework with a syntax similar to Sinatra but already has Celluloid in its
DNA.


