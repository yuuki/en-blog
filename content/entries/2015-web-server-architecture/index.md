---
title: "Web Server Architecture in 2015"
date: 2019-01-29T15:45:07+09:00
draft: true
tags: [webserver, architecture]
---

(I have translated my Japanese blog entry ([2015年Webサーバアーキテクチャ序論 05/25/2015](https://blog.yuuk.io/entry/2015-webserver-architecture)) into this English article.)

We will present an outline of the way to learn the classic web server architecture and representative implementation model mainly for new graduate web engineers.

The topic in this area was popular in the Web community was an image that was over a few years ago, but since the Web service is running on the Web server as usual, I think that it is content to learn regardless of the outbreak.
Also, HTTP/2 is finally becoming [RFC](http://www.rfc-editor.org/rfc/rfc7540.txt), and already [h2o](https://github.com/h2o/h2o) and [There is an HTTP/2 server implementation such as trusterd](https://github.com/trusterd/trusterd), and I feel that it will increase visiting the web server architecture in the future.
However, when trying to learn the Web server architecture, the information is like a mountain from the old one to the new one, and it is difficult for young people to say that they are not mindful of either the ocean or the mountain, There was, and I thought about putting it together inside once.

As an introduction, I am aiming to give a birds-eye view of the basics of Web server architecture and a role like a router to advance to more advanced topics.

# Background

I was talking to a new graduate web application engineer who joined this spring and it was said that "What is prefork?"
I think that it was when I was talking about whether it is a reasonable number because it is roughly equivalent to the number of worker processes of the application server because I am looking at the graph of the number of connections connecting to Redis from the application server. A while ago, when using AnyEvent :: Redis, there is a background that the number of connections between the application server and Redis is an abnormal numerical value and when you cease AnyEvent::Redis, it returns to normal value.

There are two implicit knowledge on this story. One is that the target application server is operating on a prefork type architecture and the other is caching connections to Redis on a per worker process basis.

Indeed, if you have written application code normally for individuals, you might not care less about how to manage the connection to a web server or DB.
Since we are using a Web application framework like Rails, deployment is an era of git pushing to Heroku, so there are few opportunities to care about how the backside is moving.
Especially because he is a new graduate he is a type that the front end is good at, so much more. I feel like teaching at the training, but there was no training to teach me about that hand.

When I thought about teaching the literature, I noticed that a systematic document to learn the mechanism of the Web server was unexpectedly found.
"Working With TCP Sockets" seems to be optimal in terms of quantity, but since the basic explanation is the explanation of the socket API, there is also a feeling that it is too much for the implementation side of the Web server.
"Technology supporting server infrastructure 4.2 Tuning Apache" may be good. We also need some knowledge of UNIX processes.

In the first place too I do not get to know how I was learning.
I can not say that I learned systematically, I think that GUU is learning in a bottom-up way like reading old articles of naoya and kazuho and reading server implementations such as Starlet .

At one time, while I was a student, I was making a basic TCP server client and hit the system call of socket API such as socket, bind, connect, listen, select, accept, read, write all , They did not understand what they mean specifically, why they are accepting in the child process, not accepting in the parent process, what non-blocking I / O is, etc.

The complexity of the historical background of the Web server architecture is accelerating the difficulty of understanding.
Regarding the architecture of the Web server, especially the Web application server, starting with CGI and including mod_xxx, FastCGI, etc., it is hard to learn the way to the current Unicorn and Starlet in turn.
Using Unicorn or Starlet means that you do not use Apache as an application server but use a web server in the same language as the application logic writing language. Perl use a web server written in Perl, and so on.

Furthermore, it is difficult to understand that there are many combinations of implementation models and models with less load, such as multithread model and for event driven other than fork's multi-process model.

At least from now on I do not think we have to learn CGI and mod_xxx to study web server architecture. In fact, we call Web server architecture here because it is one of the more general TCP server implementation models rather than Web (HTTP).
If you study and study implementation, Perl, it seems good to follow the process from Starlet to Plack, then application framework.
I do not know much prefork TCP server besides the web server, but I think that [pgpool] (http://www.pgpool.net/) was prefork.

Ultimately, what I had been saying as "classical masterpiece" reading "Unix Network Programming Second Edition Vol. 1 Network API: Socket and XTI" has become clearer.
I / O models that can be used on UNIX and the design of classic TCP servers are very well organized.
Originally published was 1990 years old, but I think that you will find that you will not lose color even if you read it. Except for circumstances peculiar to Linux, if you are in trouble around the network API, I feel like reading this.
I bought "UNIX network programming" book five years ago(2010 year), but I still have much learning even if I read it now.

<http://www.unpbook.com/>

# UNIX process and network API

In trying to understand the Web server, I think basic knowledge of UNIX, especially process and network API, is necessary.

If you learn from the beginning, I'd like to recommend "Working With Unix Processes" for the process and "Working with TCP Sockets" above for the network API.
The former "Working With Unix Processes" is translated under the title "Unix fundamentals learned by the UNIX process - Ruby", so it is easy to stick.
Regrettably the latter has not been translated, so I will read the original with spirit.

- [Working with Unix Processes](https://pragprog.com/book/jsunix/working-with-unix-processes)
- [Working with TCP Sockets](https://www.jstorimer.com/products/working-with-tcp-sockets)

As for the process, I think that it is a fundamental execution unit of a program executed on the OS and basic processing management of the OS such as parent process and child process should be known first. Generally it seems that if you know how to view the `ps` command.

As for the surroundings of the network API, it seems good to know what the socket is, the operation of each system call such as listening and accepting, the relationship between the process and the port number. Try hitting `lsof`,` netstat` command etc. and look at the file descriptor and connection state.
It's better to write a simple TCP echo server.

Since this is not enough, I will write about the port numbers and sockets I understand.

## port number

When communicating with TCP or UDP, it is impossible to distinguish each other's endpoints only by IP address. It is only the host uniquely determined by the IP address, and if it tries to communicate by TCP / UDP, it is necessary to identify that it is one of multiple processes (sshd, httpd, etc.) running on a single host .
Both TCP and UDP use different 16-bit integer port numbers to identify different processes.

By the way, the IP address is written in the IP header of the packet, and the port number is written in the TCP / UDP header of the packet.

What is a socket?
Even though it is written about how to use the socket API or written about sockets as an implementation, I do not think there are surprisingly few literature that describes what the socket expresses as a data model.
In UNIX network programming, it clearly indicated what the socket is like as follows, and the thing which was vague was clarified.
A socket is a data model that expresses end points in communication.

>
A **socket pair** (*socket pair*) of a TCP connection is a quad of a local IP address, a local TCP port, a remote IP address, and a remote TCP port, which defines both end points of the connection. One socket pair uniquely identifies a particular connection in the Internet.
>
Two values ​​that identify each endpoint, IP address and port number, are often called ** sockets ** (* socket *).
>
*UNIX Network Programming Second Edition Vol.1 p.43*

The socket is also used for connectionless network protocols such as UDP, but it says that it can be extended to UDP in the continuation of the above quotation.

>
The concept of socket pair can also be extended to UDP without connection. When describing socket functions (bind, connect, getpeername, etc.), pay attention to which function of which function operates on the socket pair. For example, bind allows the application to specify local IP and local port for both TCP and UDP sockets.
>
*UNIX Network Programming Second Edition Vol.1 p.43*

# Models of web server architecture

Basically, it only receives a request with HTTP and returns a response.
This series of flows will be referred to as request processing. In this request processing, it receives a request, parses the HTTP header, calls an appropriate handler on the application side, hits external services if necessary, puts data in DB access or queue In HTML rendering with a template engine or the like or constructing data in an arbitrary format, return the client with a response header as a response.

The main concern of the web server architecture such as the prefork model is how to efficiently and concurrently execute request processing.

If you do not have to accept a request at the same time, you can do these processes serially in the loop without thinking about anything.
However, in reality, requests from multiple clients must be processed in parallel.

In order to perform parallel processing, it is necessary to delegate request processing to some execution context such as process and thread provided by OS, lightweight thread on runtime of language, handler in event driven model, and so on.
There are as many Web server architecture models as the number of parallel processing methods, and the most rough classification is multi process, multithread, event driven, or a hybrid model of these.

The following outlines the outline of each model roughly. The way of classification is based on "UNIX Network Programming Second Edition Vol. 1" and "Working With TCP Sockets", but for example because in UNIX network programming event driven models are not introduced, Absent.

## Serial model

The simplest model. In Perl, [HTTP::Server::PSGI](https://github.com/plack/Plack/blob/master/lib/HTTP/Server/PSGI.pm) is a good implementation example. We do not process concurrently but only process it sequentially.
Because parallel processing is unnecessary for application development use of application, if it is the local environment at hand, it runs on server of serial model.

In Perl, the `IO::Socket::INET` module will do socket, bind, listen, for example, of the socket life cycle, so you may not realize that you are using too much socket API.

The figure below shows the socket life cycle of the serial model.

{{% img src="webserver_serial_model.png" %}}

1. When starting up, the server prepares to listen for connections by socket, bind, listening,
1. When accepting the connection wait until accepting actual data by accept.
1. When the data arrives, process the request and return a response to the client.
1. Close the connection with the client by closing, and wait for accept.

In any of the following models, the life cycle of the serial model is the basis.

## Multi-process model

As mentioned earlier, serial models can not process requests in parallel.
Therefore, every time a request is received, a child process is generated by fork, and the child process is allowed to process the request (1 connection per process).

It is said that fork is generally slow because it copies the entire address space of the process in memory to another address space.

However, in fact, it is a mechanism called Copy On Write (Cow) which is one of optimization methods of memory management of the OS, and the burden of instantaneous memory copying is suppressed.
When fork, CoW maps the address space of the parent process to the virtual address space of the child process, and shares the address space between the parent and the child.
When referring to memory, the child process refers to the physical address space of the parent process.
On the other hand, since it is not possible to share written pages with parents when writing to memory, copy the corresponding memory page to the child process before writing and then write it. Thereafter, do not share the memory of the corresponding page.
(In the case of fork & exec, since the child process executes a completely different program from the parent, there is no page that can be shared between parent and child, and CoW should not work)

Although the memory copy load can be suppressed with CoW, there is no doubt that extra processing will occur every time a request is made, so there is a prefork model as a method that can not be forked as much as possible.
Prefork refers to forking in advance as the word does.
When forking a certain number of child processes (in prefork, child processes are also called worker processes in some cases) at the time of server startup, we do not fork for each request.

{{% img src="webserver_multi_process_model.png" %}}

The disadvantage of the prefork type is that memory consumption is increased because it is necessary to reserve a process on the memory for only the number of simultaneous connections.
Although it can be said that it can be shared by CoW, the difference between parent and child memory pages increases as each request is processed.

In order to solve this to some extent, there is also an implementation in which the parent process kills the child process that processed the request N times and forks again.
As a result, the process is periodically dead and the memory is released, so that only the process having a relatively high memory sharing rate by CoW remains, and the memory usage can be reduced.
It is a merit that you do not have to worry about memory leak of the application so much.
There are many Web servers that can specify N with parameters like `MaxReqsPerChild`.

Another disadvantage is that you can not handle more than the number of clients at the same time as the number of child processes.
This also applies to the multi-threaded model described later.
If the number of concurrently connected clients exceeds the number of child processes, the 3-way handshaked connections will accumulate in the queue in the kernel, but since there is no one to accept, the connection will remain unprocessed. That is, a phenomenon that is generally said to be clogged easily occurs.

Starlet for Perl, Unicorn for Ruby, and so on.

## Multithreaded model

Threads are called native threads provided by the OS and green threads (Erlang's "process", Go language goroutine, etc.) implemented on the programming language VM. The latter is called a lightweight process or a lightweight thread. Here, the thread mainly refers to the former. Even when one process is running without explicitly generating a thread, sometimes it is expressed that it is operating in one thread, considering one process = 1 thread.

As for the multithread model, basically, as with the multiprocess model, there are a model (1 connection per thread) for generating threads for each request and a model (thread pool) for generating threads beforehand.

Since a thread shares an address space with a generation process, it is said that it does not copy from the entire address space like a process fork, and the cost of thread creation is generally smaller than process creation.
(http://d.hatena.ne.jp/naoya/20071010/1192040413: title: bookmark)
As a matter of fact, since fork shares the address space with CoW as mentioned above, there may not be a noticeable difference there.

Regarding memory consumption, it is said that threads are generally smaller in size, but this is a discussion similar to generation costs.

When actually trying to multithread programming, programmers should consciously avoid resource contention because multiple threads share memory address space.
On that point, since the memory address space is isolated in the multi-process model, there is the merit that it is difficult for the code to become complicated.
The reason why Postgres is more beautiful than MySQL is that the former is a multithread model, while the latter may be a multiprocess model.

## Event driven model

Model represented by Node.js and others. Both connection management and request processing from the client are executed in one thread by an event loop.

In the description of the serial model, accept, read, write etc wrote that I / O is blocked until completion.
Therefore, since one thread can not deal with multiple block processing at the same time, in the above two models, processing has been delegated to different execution contexts such as processes and threads.

I / O model that blocks processing is called blocking I / O.
There are other I / O models on UNIX, according to "UNIX Networking Programming Second Edition Vol. 6 Chapter 6" there are the following five.

>
- Blocking I / O
- Non-blocking I / O
- I / O multiplexing (select and poll)
- Signal-driven I / O
- Asynchronous I / O (aio_ function group of Posix 1)

In the blocking I / O model, processing is usually blocked by I / O of one socket, so it is difficult to handle multiple sockets with one process / thread.
Therefore, in the event driven model, by knowing from which socket the I / O exists, by multiplexing I / O among the above, in order to be able to handle multiple network I/O requests even if using blocking I/O I have to.

I/O multiplexing monitors I / O events of multiple sockets using system calls such as select / poll. With select, it is possible to call blocking I / O such as accept and read basically without blocking only on socket which can receive data.
This I/O event monitoring is called an event loop because it is implemented as a normal loop.
Calls select at the beginning of the loop, blocks until an event occurs, and resumes processing if there is an event.

The advantage of the event driven model is that, unlike prefork and thread pool, there is no upper limit on the number of clients that can connect at the same time.
Strictly speaking, there are limitations on hardware resources, the limit on the number of open descriptors, restriction on listening backlogs, etc. However, the model itself has no limit on the number of connections.

On the other hand, the disadvantage of the event driven model is that it does not multicore scale because it operates with one thread.
This is solved by the hybrid model described later.

Furthermore, as another disadvantage, there is a problem of blocking threads when writing blocking code during request processing.
For example, `libmysqlclient` is a blocking I / O premise code, so it can not be used in event driven models.
Basically, it is necessary to devise not to block processing such as using non-blocking I / O to connect with the database being processed.
In either case, it can be expected that if there is no support for asynchronous processing of the programming model at the language or framework level, it will become quite complicated code.

{{% img src="webserver_event_driven_model.png" %}}

Node.js, Twiggy in Perl, EventMachine in Ruby, Twisted in Python, Redis other than web server, and so on.

## Hybrid model

Hybrid model is a combination of the above three models.
Depending on the combination, various models are conceivable.
Here, we introduce "multiprocess / thread -> event driven" and "event driven -> multiprocess / thread".

### Multi Process / Thread -> Event Driven

In the case of a pure event driven model, since it operates only with one thread, there is a problem that it does not multicore scale.
Therefore, by combining the prefork / thread pool and the event drive model, there is a model to multicore scale.

Specifically, like a prefork or a thread pool, a certain number of worker processes / threads are generated at startup, and each worker accepts a connection by an event driven model and processes the request.

Nginx, Play 2 and so on are close to this. The former operates with prefork + event drive, the latter works with thread pool + event driven. For Perl Twiggy :: Prefork is equivalent to prefork + event driven model.

As with the event driven model, if you write code that blocks processing such as blocking I / O, care must be taken because processing of that process / thread can not handle other I / O.

### Event Driven -> Multi Process / Thread

There is a model in which the main thread handles connection management in the event loop and hands over the request processing by passing the socket of the client which the main thread got in accept in some way to the subsequent process / thread.

In the case of prefork, there is a method of passing socket (descriptor) accepted by the parent process to the child process by UNIX domain socket.
With this method, there is no need to provide a lock around accept described in the section on multi process model. This is called descriptor passing.

@kazeburo's [Monoceros](https://github.com/kazeburo/Monoceros) is close to this.

Like EventMachine, the basic is to handle connection and request processing in a single thread event loop, while some implementations provide a thread pool to move for a long time or delay the blocking process.
In the event driven model, I think that you can leave it to the thread pool when you have to write blocking by all means.

# References

The largest reference document is the book "UNIX Network Programming", but also the materials on the web are listed.

- [The C10K problem](http://www.kegel.com/c10k.html)
- [How we’ve made Phusion Passenger 5 (“Raptor”) up to 4x faster than Unicorn, up to 2x faster than Puma, Torquebox](http://www.rubyraptor.org/how-we-made-raptor-up-to-4x-faster-than-unicorn-and-up-to-2x-faster-than-puma-torquebox/)
- [Socket Sharding in NGINX Release 1.9.1](https://nginx.com/blog/socket-sharding-nginx-release-1-9-1/)

(Here are Japanese references.)

- <http://www.slideshare.net/mizzy/io-18459625>
- <http://geniee.hatenablog.com/entry/so_reuseport>
- <http://subtech.g.hatena.ne.jp/mala/20090920/1253447692>
- <http://d.hatena.ne.jp/sdyuki/20090624/1245845216>
- <http://d.hatena.ne.jp/naoya/20070311/1173629378>
- <http://d.hatena.ne.jp/naoya/20071010/1192040413>
- <http://kazeburo.hatenablog.com/entry/2013/04/15/173407>
- <http://blog.nomadscafe.jp/2010/09/apachestartservers-minmaxspareservers-maxclients.html>
- <http://qiita.com/yuroyoro/items/afb681a317561bb82470>
- <http://www.slideshare.net/kazeburo/yapc2013psgi-plack>
- <http://www.slideshare.net/kazeburo/highperfomance-plackcon1>
- <http://qiita.com/methane/items/d9db1ed5493c2d8e1c69>
- <http://frsyuki.hatenablog.com/entry/20090131/p1>
- <http://developer.cybozu.co.jp/archives/kazuho/2009/09/epoll-bac0.html>
- <http://www.aosabook.org/en/nginx.html>
- <http://developers.linecorp.com/blog/?p=1369>

Looking at this, it turns out that the story of web server architecture was a popular topic in the Japanese web industry from 2007 to 2009.
From 2010 onwards, Plack spreads around Perl, and several Web servers that run on Plack have been developed and it is also talked about.

As you read through the above references, you will find that the following related topics are developed based on what we introduced this time. Knowing this point, knowledge around the Web server architecture may come true.

- Blocking I/O, Non-blocking I/O, Asynchronous I/O, I/O multiplexing
- UNIX domain socket
- Thundering herd problem, accept mutex
- epoll/kqueue, level triggered/edge triggered notification
- HTTP keepalive
- Zero Copy
- accept4, TCP_DEFER_ACCEPT, SO_REUSEPORT
- Graceful deployment
- Lightweight process on language systems (such as Erlang processes)

# Summary

As I wrote at the beginning, I was thinking that I wanted to organize it from time to time just because it was recently talked about inside the company, so I tried to summarize myself.
I think that there are also many things that I do not understand yet but I think that if you learn from now it is likely to be helpful if there are such entries like a way to learn web server architecture I intended to write something.

Although it is an old topic, I still think that the importance of the topic has not changed so much since I am using a Web server of the same architecture.
Depending on the literature on the Web, it is definitely bottom-up learning that sometimes makes me suffer from the inability to obtain systematic knowledge. It is also a field that I personally experienced particularly remarkably that extraordinary answers are written in books that are kept being read for a long time, such as original and classical.
