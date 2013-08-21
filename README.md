redi
====

A [Redis] client [wrapper] for [Elixir].

The idea is, make the function calls resemble the commands as close as possible.

In the `redis-cli`:

    127.0.0.1:6379> set mykey "Hello, world!"

With this library in Elixir:

    iex(1)> Redi.set "mykey", "Hello, world!"

Same command but with the optional parameters, in the `redis-cli`:

    127.0.0.1:6379> set mykey "Hello, world!" EX 60 NX

With this in Elixir:

    iex(1)> Redi.set "mykey", "Hello, world!", ["EX", 60], NX

Notice how the parameters are passed. Here’s how the `SET` command is defined in the [manual]:

    SET key value [EX seconds] [PX milliseconds] [NX|XX]

See the similarities?

Installation
------------

Just add this to your `mix.exs`:

    { :redi, "0.0.7", [ github: "copperwalls/redi", tag: "v0.0.7" ] }

Or, the following to always have the latest and greatest:

    { :redi, github: "copperwalls/redi" }

Usage
-----

### One Connection Per Command ###

    iex(1)> Redi.set "mykey", "Hello, world!"
    "OK"
    iex(2)> Redi.get "mykey"
    "Hello, world!"

### Same Connection for All Commands ###

    iex(1)> db0 = Redi.connect
    #PID<0.70.0>
    iex(2)> Redi.set db0, "mykey", "Hello, world!"
    "OK"
    iex(3)> Redi.get db0, "mykey"
    "Hello, world!"
    iex(4)> Redi.del db0, "mykey"
    "1"
    iex(5)> Redi.disconnect db0
    :ok

### Connect To Another DB ###

    iex(1)> db1 = Redi.connect '127.0.0.1', 6379, 1

### Transactions ###

    iex(1)> db2 = Redi.connect '127.0.0.1', 6379, 2
    #PID<0.70.0>
    iex(2)> Redi.multi db2
    "OK"
    iex(3)> Redi.set db2, "key1", "foo"
    "QUEUED"
    iex(4)> Redi.set db2, "key2", "bar"
    "QUEUED"
    iex(5)> Redi.exec db2
    ["OK", "OK"]
    iex(6)> Redi.mget db2, ["key1", "key2"]
    ["foo", "bar"]
    iex(7)> Redi.disconnect db2
    :ok

### Pipelining ###

    iex> Redi.pipeline_query [["SET", "key1", "foo"], ["LPUSH", "key2", "bar"]]
    [ok: "OK", ok: "1"]

### Getting Help ###

For Redis commands:

    h Redi.<command>

For example, the following will display the syntax for the `ZINTERSTORE` command.

    iex> h Redi.zinterstore

Remember, though, the [official documentation] remains as the, um, *official* documentation. The above is just for convenience.

For Redi? Check the [source]—it’s the ultimate authority. It’s fairly documented, promise :)

HINT: Any [command] with a corresponding URL in the official documentation is mapped to a function—including commands with subcommands like `CLIENT` and `CONFIG` commands.

For commands with subcommands, for example, `CLIENT SETNAME`, the matching function is separated with an underscore:

    iex> Redi.client_setname "awesome"

Exception: `PUBSUB` has subcommands but even though they do not (though, I think, they should) have a corresponding URL in the official documentation, they have a matching function.

In the `redis-cli`:

    PUBSUB NUMPAT

Here:

    Redi.pubsub_numpat

Other Supported Functions
-------------------------

Thanks to [exredis], the underlying library, if there are any missing functions here (but are available in that wonderful library), feel free to call those functions directly. e.g., `Exredis.<function>`

Tests
-----

Noticed those `iex` sessions in the `h` (help) function above? Those are from the documentation inside the code, right? Elixir can use them as unit tests. Read that again. Documention as unit tests—talk about hitting two birds with one stone! THAT. IS. PRETTY. COOL.

    $ cd redi && mix test

Will run all the tests found in the `test` directory *and* those `iex` sessions in the documentation mentioned above.

WARNING: The tests will create and destroy *test* data. That said, better NOT run the tests against a server with important data. Also, the tests will spawn hundreds of connections to the Redis server. You have been warned.

Background
----------

This started as an experiment to learn something about Elixir’s build tool, [Mix], and Elixir’s unit test framework, [ExUnit]. Though I learned something about both, this turned out to be the best way to learn a lot about Redis :)

License
-------

Copyright (c) 2013 ed.o

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Redis]:http://redis.io/
[Elixir]:http://elixir-lang.org/
[manual]:http://redis.io/commands/set
[official documentation]:http://redis.io/commands
[source]:https://github.com/copperwalls/redi/blob/master/lib/redi.ex
[command]:http://redis.io/commands
[exredis]:https://github.com/artemeff/exredis
[Mix]:http://elixir-lang.org/getting_started/mix/1.html
[ExUnit]:http://elixir-lang.org/getting_started/ex_unit/1.html

