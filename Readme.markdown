** FIRST OF ALL **
This is a WIP!

Humpty
======

Humpty is be a Sinatra Application which provides administrative access to one or more RabbitMQ servers. It uses REST Resources provided by [alice](http://github.com/auser/alice) to retrieve information from the RabbitMQ server which is not exposed by the AMQP protocol itself.

As an addition to alice's features, humpty allows basic manipulation of Queues, bindings and exchanges. Currently only deletion of queues is supported, but other operations such as creating queues, binding exchanges to queues, will be supported soon.

It is planed to allow monitoring of queue sizes (graphs for the win!) in the near future.

Quickstart
==========
1. install [alice](http://github.com/auser/alice) and start it
2. install bundler (gem install bundler)
3. gem bundle
4. copy the default config from config/config.yml.default to config/config.yml and edit the defaults as needed
4. ruby humpty.rb
5. visit localhost:4567 in your webbrowser

Configuration
=============
Add a configuration entry for every server you wan't to make accessible by humpty. A alice node needs to run on every Server which is added in the configuration file. The name for the broker can be chosen freely (as long as it is unique) since it is only used by humpty to distinguish the several servers and for the web frontend.

    name_of_broker1:
        rabbitmq:
            host: localhost
        alice:
            base_url: http://localhost
            port: 9999
    name_of_broker2:
        rabbitmq:
            host: my.fanzy.host
        alice:
            base_url: http://my.fanzy.host
            port: 9988

FAQ
===
Q: why not use wonderland?<br/>
A: I suck at Javascript 

Q: is humpty already usable?<br/>
A: c'mon are you kiddin me? I've just pushed the first couple of LOC. haha, try again later

Q: alice doesnt start correctly :(<br/>
A: Have a look at alice project page. helped me a lot.<br/>
   (I, for example, had to start it with `./start.sh -sname alice -setcookie "MYERLANGCOOKIE"`)