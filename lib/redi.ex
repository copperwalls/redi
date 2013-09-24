defmodule Redi do

  use Exredis

  @moduledoc """
  Redis client for Elixir
  """

  # Start of internal functions

  @doc """
  Connect to a Redis server

      client = Redi.connect

  The default is to connect to DB 0. To connect to another DB, just add some
  parameters like so:

      db1 = Redi.connect '127.0.0.1', 6379, 1

  That will connect to the DB 1 on the Redis server port 6379 running on the
  localhost. (It is probably a good idea to name the client based on the DB
  it is connected to.)

  Note: `host` should be a list (i.e. use single instead of double quotes)

  """
  def connect(host // '127.0.0.1', port // 6379, db // 0, password // '',
              reconnect_sleep // :no_reconnect) when is_list(host) and
              is_integer(port) and is_integer(db),

    do: start(host, port, db, password, reconnect_sleep)

  @doc """
  Connect to a Redis server (for subscribing to a channel)

  #FIXME

  """
  def sub_connect() do
  end

  @doc """
  Disconnect from a Redis server

      Redi.disconnect client

  Note: `client` is the PID returned by the `Redi.connect` command.
  """
  def disconnect(client) when is_pid(client), do: stop(client)

  @doc """
  Make a pipeline query

      Redi.pipeline_query [[command1], [command2], [command3]]

  """
  def pipeline_query(client // connect, command_list) when is_pid(client) and
                     is_list(command_list),

    do: query_pipe(client, command_list)

  # Start of Redis commands

  @doc """
  ## APPEND key, value

  Append a value to a key

  Time complexity: O(1). The amortized time complexity is O(1) assuming the
  appended value is small and the already present value is of any size, since
  the dynamic string library used by Redis will double the free space available
  on every reallocation.

  More info: http://redis.io/commands/append

  ## Return value

  Integer reply: the length of the string after the append operation.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "akey"
        "0"
        iex> Redi.exists db, "akey"
        "0"
        iex> Redi.append db, "akey", "Hello"
        "5"
        iex> Redi.append db, "akey", " World"
        "11"
        iex> Redi.get db, "akey"
        "Hello World"
        iex> Redi.del db, "akey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def append(client // connect, key, value),
    do: query(client, [ "APPEND", key, value ])

  @doc """
  ## AUTH password

  Authenticate to the server

  More info: http://redis.io/commands/auth

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def auth(client // connect, password), do: query(client, [ "AUTH", password ])

  @doc """
  ## BGREWRITEAOF

  Asynchronously rewrite the append-only file

  More info: http://redis.io/commands/bgrewriteaof

  ## Return value

  Status code reply. Always OK.

  """
  def bgrewriteaof(client // connect), do: query(client, [ "BGREWRITEAOF" ])

  @doc """
  ## BGSAVE

  Asynchronously save the dataset to disk

  More info: http://redis.io/commands/bgsave

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def bgsave(client // connect), do: query(client, [ "BGSAVE" ])

  @doc """
  ## BITCOUNT key [start] [end]

  Count set bits in a string

  Time complexity: O(N)

  More info: http://redis.io/commands/bitcount

  ## Return value

  Integer reply

  The number of bits set to 1.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "bitkey"
        "0"
        iex> Redi.set db, "bitkey", "foobar"
        "OK"
        iex> Redi.bitcount db, "bitkey"
        "26"
        iex> Redi.bitcount db, "bitkey", 0, 0
        "4"
        iex> Redi.bitcount db, "bitkey", 1, 1
        "6"
        iex> Redi.del db, "bitkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def bitcount(client // connect, key, start_bit // nil, end_bit // nil)

  # For Redi.bitcount client, "key"
  def bitcount(client, key, start_bit, end_bit) when is_pid(client) and
               nil?(start_bit) and nil?(end_bit),

    do: query(client, [ "BITCOUNT", key, 0, -1 ])

  # For Redi.bitcount client, "key", start_bit
  def bitcount(client, key, start_bit, end_bit) when is_pid(client) and
               nil?(end_bit),

    do: query(client, [ "BITCOUNT", key, start_bit, -1 ])

  # For Redi.bitcount "key"
  def bitcount(key, start_bit, end_bit, _) when not is_pid(key) and
               nil?(start_bit) and nil?(end_bit),

    do: connect |> query [ "BITCOUNT", key, 0, -1 ]

  # For Redi.bitcount "key", start_bit
  def bitcount(key, start_bit, end_bit, _) when not is_pid(key) and
               nil?(end_bit),

    do: connect |> query [ "BITCOUNT", key, start_bit, -1 ]

  # For Redi.bitcount "key", start_bit, end_bit
  def bitcount(key, start_bit, end_bit, _) when not is_pid(key),

    do: connect |> query [ "BITCOUNT", key, start_bit, end_bit ]

  # For Redi.bitcount client, "key", start_bit, end_bit
  def bitcount(client, key, start_bit, end_bit),

    do: query(client, [ "BITCOUNT", key, start_bit, end_bit ])

  @doc """
  ## BITOP operation destkey key [key ...]

  Perform bitwise operations between strings

  Time complexity: O(N)

  More info: http://redis.io/commands/bitop

  ## Return value

  Integer reply

  The size of the string store in the destination key, that is equal
  to the size of the longest input string.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["b2key1", "b2key2", "dest"]
        "0"
        iex> Redi.set db, "b2key1", "foobar"
        "OK"
        iex> Redi.set db, "b2key2", "abcdef"
        "OK"
        iex> Redi.bitop db, "AND", "dest", ["b2key1", "b2key2"]
        "6"
        iex> Redi.get db, "dest"
        "`bc`ab"
        iex> Redi.del db, ["b2key1", "b2key2", "dest"]
        "3"
        iex> Redi.disconnect db
        :ok

  """
  def bitop(client // connect, operation, destkey, key) do
    if is_list(key) do
      query(client, [ "BITOP" | [ operation | [ destkey | key ] ] ])
    else
      query(client, [ "BITOP", operation, destkey, key ])
    end
  end

  @doc """
  ## BLPOP key [key ...] timeout

  Remove and get the first element in a list, or block until one is available

  Time complexity: O(1)

  More info: http://redis.io/commands/blpop

  ## Return value

  Multi-bulk reply: specifically:

  * A nil multi-bulk when no element could be popped and the timeout expired.
  * A two-element multi-bulk with the first element being the name of the key
    where an element was popped and the second element being valueo of the
    popped element.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["blist1", "blist2"]
        "0"
        iex> Redi.rpush db, "blist1", ["a", "b", "c"]
        "3"
        iex> Redi.blpop db, ["blist1", "blist2"], 0
        ["blist1", "a"]
        iex> Redi.del db, ["blist1", "blist2"]
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def blpop(client // connect, key, timeout) do
    if is_list(key) do
      query(client, [ "BLPOP" | key ++ [timeout] ])
    else
      query(client, [ "BLPOP", key, timeout ])
    end
  end

  @doc """
  ## BRPOP key [key ...] timeout

  Remove and get the last element in a list, or block until one is available

  Time complexity: O(1)

  More info: http://redis.io/commands/brpop

  ## Return value

  Multi-bulk reply: specifically:

  * A nil multi-bulk when no element could be popped and the timeout expired.
  * A two-element multi-bulk with the first element being the name of the key
    where an element was popped and the second element being the value of the
    popped element.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["brlist1", "brlist2"]
        "0"
        iex> Redi.rpush db, "brlist1", ["a", "b", "c"]
        "3"
        iex> Redi.brpop db, ["brlist1", "brlist2"], 0
        ["brlist1", "c"]
        iex> Redi.del db, ["brlist1", "brlist2"]
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def brpop(client // connect, key, timeout) do
    if is_list(key) do
      query(client, [ "BRPOP" | key ++ [timeout] ])
    else
      query(client, [ "BRPOP", key, timeout ])
    end
  end

  @doc """
  ## BRPOPLPUSH source destination timeout

  Pop a value from a list, push it to another list and return it; or block
  until one is available

  Time complexity: O(1)

  More info: http://redis.io/commands/brpoplpush

  ## Return value

  Bulk reply: the element being popped from source and pushed to destination.
  If timeout is reached, a Null multi-bulk reply is returned.

  """
  def brpoplpush(client // connect, source, destination, timeout),
    do: query(client, [ "BRPOPLPUSH", source, destination, timeout ])

  @doc """
  ## CLIENT GETNAME

  Get the current connection name

  Time complexity: O(1)

  More info: http://redis.io/commands/client-getname

  ## Return value

  Bulk reply. The connection name, or a null bulk reply if no name is set.

  """
  def client_getname(client // connect),
    do: query(client, [ "CLIENT", "GETNAME" ])

  @doc """
  ## CLIENT KILL ip:port

  Kill the connection of a client

  Time complexity: O(N) where N is the number of client connections

  More info: http://redis.io/commands/client-kill

  ## Return value

  Status code reply. OK if the connection exists and has been closed.

  """
  def client_kill(client // connect, ip_port),
    do: query(client, [ "CLIENT", "KILL", ip_port ])

  @doc """
  ## CLIENT LIST

  Get the list of client connections

  Time complexity: O(N) where N is the number of client connections

  More info: http://redis.io/commands/client-list

  ## Return value

  Bulk reply. A unique string, formatted as follows:

  * One client connection per line (separated by LF)
  * Each line is composed of a succession of property=value fields
    separated by a space character.

  """
  def client_list(client // connect),
    do: query(client, [ "CLIENT", "LIST" ])

  @doc """
  ## CLIENT SETNAME connection-name

  Get the current connection name

  Time complexity: O(1)

  More info: http://redis.io/commands/client-setname

  ## Return value

  Status code reply. OK if the connection name was successfully set.

  """
  def client_setname(client // connect, connection_name),
    do: query(client, [ "CLIENT", "SETNAME", connection_name ])

  @doc """
  ## CONFIG GET parameter

  Get the value of a configuration parameter

  More info: http://redis.io/commands/config-get

  ## Return value

  [Bulk reply.](http://redis.io/topics/protocol#bulk-reply)

  """
  def config_get(client // connect, parameter),
    do: query(client, [ "CONFIG", "GET", parameter ])

  @doc """
  ## CONFIG RESETSTAT

  Reset the stats returned by INFO

  Time complexity: O(1)

  More info: http://redis.io/commands/config-resetstat

  ## Return value

  Status code reply. Always OK.

  """
  def config_resetstat(client // connect),
    do: query(client, [ "CONFIG", "RESETSTAT" ])

  @doc """
  ## CONFIG REWRITE

  Rewrite the configuration file with the in-memory configuration

  Time complexity: O(1)

  More info: http://redis.io/commands/config-rewrite

  ## Return value

  Status code reply. OK when the configuration was written properly.
  Otherwise an error is returned.

  """
  def config_rewrite(client // connect),
    do: query(client, [ "CONFIG", "REWRITE" ])

  @doc """
  ## CONFIG SET

  Set a configuration parameter to the given value

  More info: http://redis.io/commands/config-set

  ## Return value

  Status code reply. OK when the configuration was set properly.
  Otherwise an error is returned.

  """
  def config_set(client // connect, parameter, value) do
    if is_list(value) do
      query(client, [ "CONFIG" | [ "SET" | [ parameter | value ] ] ])
    else
      query(client, [ "CONFIG", "SET", parameter, value ])
    end
  end

  @doc """
  ## DBSIZE

  Return the number of keys in the selected database

  More info: http://redis.io/commands/dbsize

  ## Return value

  [Integer reply.](http://redis.io/topics/protocol#integer-reply)

  """
  def dbsize(client // connect), do: query(client, [ "DBSIZE" ])

  @doc """
  ## DEBUG OBJECT key

  Get debugging information about a key

  More info: http://redis.io/commands/debug-object

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def debug_object(client // connect, key),
    do: query(client, [ "DEBUG", "OBJECT", key ])

  @doc """
  ## DEBUG SEGFAULT

  Get debugging information about a key

  More info: http://redis.io/commands/debug-segfault

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def debug_segfault(client // connect),
    do: query(client, [ "DEBUG", "SEGFAULT" ])

  @doc """
  ## DECR key

  Decrement the integer value of a key by one

  Time complexity: O(1)

  More info: http://redis.io/commands/decr

  ## Return value

  Integer reply: the value of key after the decrement

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "dckey"
        "0"
        iex> Redi.set db, "dckey", "10"
        "OK"
        iex> Redi.decr db, "dckey"
        "9"
        iex> Redi.set db, "dckey", "234293482390480948029348230948"
        "OK"
        iex> Redi.decr db, "dckey"
        "ERR value is not an integer or out of range"
        iex> Redi.del db, "dckey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def decr(client // connect, key), do: query(client, [ "DECR", key ])

  @doc """
  ## DECRBY key decrement

  Decrement the integer value of a key by the given number

  Time complexity: O(1)

  More info: http://redis.io/commands/decrby

  ## Return value

  Integer reply: the value of key after the decrement

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "dbkey"
        "0"
        iex> Redi.set db, "dbkey", "10"
        "OK"
        iex> Redi.decrby db, "dbkey", 5
        "5"
        iex> Redi.del db, "dbkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def decrby(client // connect, key, decrement),
    do: query(client, [ "DECRBY", key, decrement ])

  @doc """
  ## DEL key [key ...]

  Delete a key

  Time complexity: O(N) where N is the number of keys that will be removed.
  When a key to remove holds a value other than a string, the individual
  complexity for this key is O(M) where M is the number of elements in the
  list, set, sorted set or hash. Removing a single key that holds a string
  value is O(1).

  More info: http://redis.io/commands/del

  ## Return value

  Integer reply: The number of keys that were removed.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["dkey1", "dkey2"]
        "0"
        iex> Redi.set db, "dkey1", "Hello"
        "OK"
        iex> Redi.set db, "dkey2", "World"
        "OK"
        iex> Redi.del db, ["dkey1", "dkey2", "dkey3"]
        "2"
        iex> Redi.disconnect db
        :ok

  """
  def del(client // connect, key) do
    if is_list(key) do
      query(client, [ "DEL" | key ])
    else
      query(client, [ "DEL", key ])
    end
  end

  @doc """
  ## DISCARD

  Discard all commands issued after MULTI

  More info: http://redis.io/commands/discard

  ## Return value

  Status code reply. Always OK.

  """
  def discard(client // connect), do: query(client, [ "DISCARD" ])

  @doc """
  ## DUMP key

  Return a serialized version of the value stored at the specified key

  Time complexity: O(1) to access the key and additional O(N*M) to serialize
  it, where N is the number of Redis objects composing the value and M their
  average size. For small string values the time complexity is thus O(1)+O(1*M)
  where M is small, so simply (O)1.

  More info: http://redis.io/commands/dump

  ## Return value

  Bulk reply: the serialized value.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del "dmkey"
        "0"
        iex> Redi.set "dmkey", 10
        "OK"
        iex> Redi.dump "dmkey"
        <<0, 192, 10, 6, 0, 248, 114, 63, 197, 251, 251, 95, 40>>
        iex> Redi.del "dmkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def dump(client // connect, key), do: query(client, [ "DUMP", key ])

  @doc """
  ## ECHO message

  Echo the given string

  More info: http://redis.io/commands/echo

  ## Return value

  [Bulk reply](http://redis.io/topics/protocol#bulk-reply)

  ## Examples

    iex> Redi.echo "Hello World!"
    "Hello World!"

  """
  def echo(client // connect, message), do: query(client, [ "ECHO", message ])

  @doc """
  ## EVAL script numkeys key [key ...] arg [arg ...]

  Execute a Lua script server-side

  Time complexity: Depends on the script that is executed.

  More info: http://redis.io/commands/eval

  """
  def eval(client // connect, script, numkeys, key // nil, arg // nil)

  # For Redi.eval client, "script", numkeys, "key"
  # Also for Redi.eval client, "script", numkeys, ["key", "arg"]
  def eval(client, script, numkeys, key, arg) when is_pid(client) and
           nil?(arg) do

    if is_list(key) do
      query(client, [ "EVAL" | [ script | [ numkeys | key ] ] ])
    else
      query(client, [ "EVAL", script, numkeys, key ])
    end

  end

  # For Redi.eval client, "script", numkeys
  def eval(client, script, numkeys, key, _) when is_pid(client) and nil?(key),
    do: query(client, [ "EVAL", script, numkeys ])

  # For Redi.eval "script", numkeys, "key"
  # Also for Redi.eval "script", numkeys, ["key", "arg"]
  def eval(script, numkeys, key, arg, _) when not is_pid(script) and
           nil?(arg) do

    if is_list(key) do
      connect |> query [ "EVAL" | [ script | [ numkeys | key ] ] ]
    else
      connect |> query [ "EVAL", script, numkeys, key ]
    end

  end

  # For Redi.eval client, "script", numkeys, ["key1", "key2"], ["arg1", "arg2"]
  # Also for Redi.eval client, "script", numkeys, "key", "arg"
  def eval(client, script, numkeys, key, arg) do
    if is_list(key) and is_list(arg) do
      query(client, [ "EVAL" | [ script | [ numkeys | key ++ arg ] ] ])
    else
      query(client, [ "EVAL", script, numkeys, key, arg ])
    end
  end

  @doc """
  ## EVALSHA sha1 numkeys key [key ...] arg [arg ...]

  Execute a Lua script server-side

  Time complexity: Depends on the script that is executed.

  More info: http://redis.io/commands/evalsha

  """
  def evalsha(client // connect, sha1, numkeys, opt1 // nil, opt2 // nil)

  # For Redi.evalsha client, "sha1", numkeys, "key"
  # Also for Redi.evalsha client, "sha1", numkeys, ["key", "arg"]
  def evalsha(client, sha1, numkeys, opt1, opt2) when is_pid(client) and
              nil?(opt2) do

    if is_list(opt1) do
      query(client, [ "EVALSHA" | [ sha1 | [ numkeys | opt1 ] ] ])
    else
      query(client, [ "EVALSHA", sha1, numkeys, opt1 ])
    end

  end

  # For Redi.evalsha client, "sha1", numkeys
  def evalsha(client, sha1, numkeys, opt1, _)
    when nil?(opt1) and is_pid(client),
      do: query(client, [ "EVALSHA", sha1, numkeys ])

  # For Redi.evalsha "sha1", numkeys, "key"
  # Also for Redi.evalsha "sha1", numkeys, ["key", "arg"]
  def evalsha(sha1, numkeys, opt1, opt2, _) when not is_pid(sha1) and
              nil?(opt2) do

      if is_list(opt1) do
        connect |> query [ "EVALSHA" | [ sha1 | [ numkeys | opt1 ] ] ]
      else
        connect |> query [ "EVALSHA", sha1, numkeys, opt1 ]
      end

  end

  # For Redi.evalsha client, "sha1", numkeys, ["key1", "key2"], ["arg1", "arg2"]
  # Also for Redi.evalsha client, "sha1", numkeys, "key", "arg"
  def evalsha(client, sha1, numkeys, key, arg) do
    if is_list(key) and is_list(arg) do
      query(client, [ "EVALSHA" | [ sha1 | [ numkeys | key ++ arg ] ] ])
    else
      query(client, [ "EVALSHA", sha1, numkeys, key, arg ])
    end
  end

  @doc """
  ## EXEC

  Execute all commands issued after MULTI

  More info: http://redis.io/commands/exec

  ## Return value

  Multi-bulk reply. Each element being the reply to each of the commands
  in the atomic transaction. When using WATCH, EXEC can return a Null
  multi-bulk reply if the execution was aborted.

  """
  def exec(client // connect), do: query(client, [ "EXEC" ])

  @doc """
  ## EXISTS key

  Determine if a key exists

  Time complexity: O(1)

  More info: http://redis.io/commands/exists

  ## Return value

  Integer reply, specifically:

  * 1 if the key exists
  * 0 if the key does not exist

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "exkey1"
        "0"
        iex> Redi.set db, "exkey1", "Hello"
        "OK"
        iex> Redi.exists db, "exkey1"
        "1"
        iex> Redi.exists db, "exkey0"
        "0"
        iex> Redi.del db, "exkey1"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def exists(client // connect, key), do: query(client, [ "EXISTS", key ])

  @doc """
  ## EXPIRE key seconds

  Set a key's time to live in seconds

  Time complexity: O(1)

  More info: http://redis.io/commands/expire

  ## Return value

  Integer reply, specifically:

  * 1 if the timeout was set
  * 0 if key does not exist or the timout could not be set

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "exkey"
        "0"
        iex> Redi.set db, "exkey", "Hello"
        "OK"
        iex> Redi.expire db, "exkey", 10
        "1"
        iex> Redi.ttl db, "exkey"
        "10"
        iex> Redi.set db, "exkey", "Hello World"
        "OK"
        iex> Redi.ttl db, "exkey"
        "-1"
        iex> Redi.del db, "exkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def expire(client // connect, key, seconds),
    do: query(client, [ "EXPIRE", key, seconds ])

  @doc """
  ## EXPIREAT key timestamp

  Set the expiration for a key as a UNIX timestamp

  Time complexity: O(1)

  More info: http://redis.io/commands/expireat

  ## Return value

  Integer reply, specifically:

  * 1 if the timeout was set
  * 0 if key does not exist or the timout could not be set (See: EXPIRE)

  ## Examples

        iex> db = Redi.connect
        iex> Redi.set db, "eakey", "Hello"
        "OK"
        iex> Redi.exists db, "eakey"
        "1"
        iex> Redi.expireat db, "eakey", 1375247301
        "1"
        iex> Redi.exists db, "eakey"
        "0"
        iex> Redi.disconnect db
        :ok

  """
  def expireat(client // connect, key, timestamp),
    do: query(client, [ "EXPIREAT", key, timestamp ])


  @doc """
  ## FLUSHALL

  Remove all keys from all databases

  More info: http://redis.io/commands/flushall

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def flushall(client // connect), do: query(client, [ "FLUSHALL" ])

  @doc """
  ## FLUSHDB

  Remove all keys from the current database

  More info: http://redis.io/commands/flushdb

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def flushdb(client // connect), do: query(client, [ "FLUSHDB" ])

  @doc """
  ## GET key

  Get the value of a key

  Time complexity: O(1)

  More info: http://redis.io/commands/get

  ## Return value

  Bulk reply: the value of key, or nil when key does not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "gkey"
        "0"
        iex> Redi.get db, "nonexisting"
        :undefined
        iex> Redi.set db, "gkey", "Hello"
        "OK"
        iex> Redi.get db, "gkey"
        "Hello"
        iex> Redi.del db, "gkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def get(client // connect, key), do: query(client, [ "GET", key ])

  @doc """
  ## GETBIT key offset

  Returns the bit value at offset in the string value stored at key

  Time complexity: O(1)

  More info: http://redis.io/commands/getbit

  ## Return value

  Integer reply: the bit value stored at offset.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "gbkey"
        "0"
        iex> Redi.setbit db, "gbkey", 7, 1
        "0"
        iex> Redi.getbit db, "gbkey", 0
        "0"
        iex> Redi.getbit db, "gbkey", 7
        "1"
        iex> Redi.getbit db, "gbkey", 100
        "0"
        iex> Redi.del db, "gbkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def getbit(client // connect, key, offset),
    do: query(client, [ "GETBIT", key, offset ])

  @doc """
  ## GETRANGE key start end

  Get a substring of the string stored at a key

  Time complexity: O(N) where N is the length of the returned string.
  The complexity is ultimately determined by the returned length, but
  because creating a substring from an existing string is very cheap,
  it can be considered O(1) for small strings.

  More info: http://redis.io/commands/getrange

  ## Return value

  Bulk reply

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "grkey"
        "0"
        iex> Redi.set db, "grkey", "This is a string"
        "OK"
        iex> Redi.getrange db, "grkey", 0, 3
        "This"
        iex> Redi.getrange db, "grkey", -3, -1
        "ing"
        iex> Redi.getrange db, "grkey", 0, -1
        "This is a string"
        iex> Redi.getrange db, "grkey", 10, 100
        "string"
        iex> Redi.del db, "grkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def getrange(client // connect, key, range_start, range_end),
    do: query(client,
      [ "GETRANGE", key, to_string(range_start), to_string(range_end) ])

  @doc """
  ## GETSET key value

  Set the string value of a key and return its old value

  Time complexity: O(1)

  More info: http://redis.io/commands/getset

  ## Return value

  Bulk reply: the old value stored at key, or nil when key did not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "gskey"
        "0"
        iex> Redi.set db, "gskey", "Hello"
        "OK"
        iex> Redi.getset db, "gskey", "World"
        "Hello"
        iex> Redi.get db, "gskey"
        "World"
        iex> Redi.del db, "gskey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def getset(client // connect, key, value),
    do: query(client, [ "GETSET", key, value ])

  @doc """
  ## HDEL key field [field ...]

  Delete one or more hash fields

  Time complexity: O(1)

  More info: http://redis.io/commands/hdel

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "field1"
        "0"
        iex> Redi.hset db, "hdhash", "field1", "foo"
        "1"
        iex> Redi.hdel db, "hdhash", "field1"
        "1"
        iex> Redi.hdel db, "hdhash", "field2"
        "0"
        iex> Redi.disconnect db
        :ok

  """
  def hdel(client // connect, key, field) do
    if is_list(field) do
      query(client, [ "HDEL" | [ key | field ] ])
    else
      query(client, [ "HDEL", key, field ])
    end
  end

  @doc """
  ## HEXISTS key field

  Determine if a hash field exists

  Time complexity: O(1)

  More info: http://redis.io/commands/hexists

  ## Return value

  Integer reply, specifically:

  * 1 if the hash contains field
  * 0 if the hash does not contain field, or key does not exist

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hehash"
        "0"
        iex> Redi.hset db, "hehash", "field1", "foo"
        "1"
        iex> Redi.hexists db, "hehash", "field1"
        "1"
        iex> Redi.hexists db, "hehash", "field2"
        "0"
        iex> Redi.del db, "hehash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hexists(client // connect, key, field),
    do: query(client, [ "HEXISTS", key, field ])

  @doc """
  ## HGET key field

  Get the value of a hash field

  Time complexity: O(1)

  More info: http://redis.io/commands/hget

  ## Return value

  Buld reply: the value associated with field, or nil when field is not
  present in the hash or key does not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hghash"
        "0"
        iex> Redi.hset db, "hghash", "field1", "foo"
        "1"
        iex> Redi.hget db, "hghash", "field1"
        "foo"
        iex> Redi.hget db, "hghash", "field2"
        :undefined
        iex> Redi.del db, "hghash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hget(client // connect, key, field),
    do: query(client, [ "HGET", key, field ])

  @doc """
  ## HGETALL key

  Get all the fields and values in a hash

  Time complexity: O(N) where N is the size of the hash

  More info: http://redis.io/commands/hgetall

  ## Return value

  Multi-bulk reply: list of fields and their values stored in the hash,
  or an empty list when key does not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hahash"
        "0"
        iex> Redi.hset db, "hahash", "field1", "Hello"
        "1"
        iex> Redi.hset db, "hahash", "field2", "World"
        "1"
        iex> Redi.hgetall db, "hahash"
        ["field1", "Hello", "field2", "World"]
        iex> Redi.del db, "hahash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hgetall(client // connect, key), do: query(client, [ "HGETALL", key ])

  @doc """
  ## HINCRBY key field increment

  Increment the integer value of a hash field by the given number

  Time complexity: O(1)

  More info: http://redis.io/commands/hincrby

  ## Return value

  Integer reply: the value at field after the increment operation.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hihash"
        "0"
        iex> Redi.hset db, "hihash", "field", 5
        "1"
        iex> Redi.hincrby db, "hihash", "field", 1
        "6"
        iex> Redi.hincrby db, "hihash", "field", "-1"
        "5"
        iex> Redi.hincrby db, "hihash", "field", "-10"
        "-5"
        iex> Redi.del db, "hihash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hincrby(client // connect, key, field, increment),
    do: query(client, [ "HINCRBY", key, field, to_string(increment) ])

  @doc """
  ## HINCRBYFLOAT key field increment

  Increment the float value of a hash field by the given amount

  Time complexity: O(1)

  More info: http://redis.io/commands/hincrbyfloat

  ## Return value

  Bulk reply: the value of field after the increment.

  ## Example

        iex> db = Redi.connect
        iex> Redi.del db, "hfkey"
        "0"
        iex> Redi.hset db, "hfkey", "field", 10.50
        "1"
        iex> Redi.hincrbyfloat db, "hfkey", "field", 0.1
        "10.6"
        iex> Redi.hset db, "hfkey", "field", "5.0e3"
        "0"
        iex> Redi.hincrbyfloat db, "hfkey", "field", "2.0e2"
        "5200"
        iex> Redi.del db, "hfkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hincrbyfloat(client // connect, key, field, increment),
    do: query(client, [ "HINCRBYFLOAT", key, field, to_string(increment) ])

  @doc """
  ## HKEYS key

  Get all the fields in a hash

  Time complexity: O(N) where N is the size of the hash.

  More info: http://redis.io/commands/hkeys

  ## Return value

  Multi-bulk reply: list of fields in the hash, or an empty list when key
  does not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hkhash"
        "0"
        iex> Redi.hset db, "hkhash", "field1", "Hello"
        "1"
        iex> Redi.hset db, "hkhash", "field2", "World"
        "1"
        iex> Redi.hkeys db, "hkhash"
        ["field1", "field2"]
        iex> Redi.del db, "hkhash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hkeys(client // connect, key), do: query(client, [ "HKEYS", key ])

  @doc """
  ## HLEN key

  Get the number of fields in a hash

  Time complexity: O(1)

  More info: http://redis.io/commands/hlen

  ## Return value

  Integer reply: number of fiedls in the hash, or 0 when key does not exist.

  ## Example

        iex> db = Redi.connect
        iex> Redi.del db, "hlhash"
        "0"
        iex> Redi.hset db, "hlhash", "field1", "Hello"
        "1"
        iex> Redi.hset db, "hlhash", "field2", "World"
        "1"
        iex> Redi.hlen db, "hlhash"
        "2"
        iex> Redi.del db, "hlhash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hlen(client // connect, key), do: query(client, [ "HLEN", key ])

  @doc """
  ## HMGET key field [field ...]

  Get the values of all the given hash fields

  Time complexity: O(N) where N is the number of fields being requested.

  More info: http://redis.io/commands/hmget

  ## Return value

  Multi-bulk reply: list of values associated with the given fields,
  in the same order as they are requested.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hmhash"
        "0"
        iex> Redi.hset db, "hmhash", "field1", "Hello"
        "1"
        iex> Redi.hset db, "hmhash", "field2", "World"
        "1"
        iex> Redi.hmget db, "hmhash", ["field1", "field2", "nofield"]
        ["Hello", "World", :undefined]
        iex> Redi.del db, "hmhash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hmget(client // connect, key, field) do
    if is_list(field) do
      query(client, [ "HMGET" | [ key | field ] ])
    else
      query(client, [ "HMGET", key, field ])
    end
  end

  @doc """
  ## HMSET key field value [field value ...]

  Set multiple hash fields to multiple values

  Time complexity: O(N) where N is the number of fields being set.

  More info: http://redis.io/commands/hmset

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hmshash"
        "0"
        iex> Redi.hmset db, "hmshash", ["field1", "Hello", "field2", "World"]
        "OK"
        iex> Redi.hget db, "hmshash", "field1"
        "Hello"
        iex> Redi.hget db, "hmshash", "field2"
        "World"
        iex> Redi.del db, "hmshash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hmset(client // connect, key, field // nil, value // nil)

  # For Redi.hmset client, "key", ["f1", "v1", "f2", "v2", "fn", "vn"]
  def hmset(client, key, field_value, opt2) when is_pid(client) and
            is_list(field_value) and nil?(opt2),

    do: query(client, [ "HMSET" | [ key | field_value ] ])

  # For Redi.hmset "key", ["f1", "v1", "f2", "v2", "fn", "vn"]
  def hmset(key, field_value, opt2, _) when not is_pid(key) and
            is_list(field_value) and nil?(opt2),

    do: connect |> query [ "HMSET" | [ key | field_value ] ]

  # For Redi.hmset "key", "f1", "v1"
  def hmset(key, field, value, _) when not is_pid(key),
    do: connect |> query [ "HMSET", field, value ]

  # For Redi.hmset client, "key", "f1", "v1"
  def hmset(client, key, field, value),
    do: query(client, [ "HMSET", key, field, value ])

  @doc """
  ## HSET key field value

  Set the string value of a hash field

  Time complexity: O(1)

  More info: http://redis.io/commands/hset

  ## Return value

  Integer reply, specifically

  * 1 if field is a new field in the hash and value was set
  * 0 if field already exists in the hash and the value was updated

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hshash"
        "0"
        iex> Redi.hset db, "hshash", "field1", "Hello"
        "1"
        iex> Redi.hget db, "hshash", "field1"
        "Hello"
        iex> Redi.del db, "hshash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hset(client // connect, key, field, value),
    do: query(client, [ "HSET", key, field, to_string(value) ])

  @doc """
  ## HSETNX key field value

  Set the value of a hash field, only if the field does not exist

  Time complexity: O(1)

  More info: http://redis.io/commands/hsetnx

  ## Return value

  Integer reply, specifically:

  * 1 if field is a new field in the hash and value was set
  * 0 if field already exists in the hash and no operation was performed

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hsnhash"
        "0"
        iex> Redi.hsetnx db, "hsnhash", "field", "Hello"
        "1"
        iex> Redi.hsetnx db, "hsnhash", "field", "World"
        "0"
        iex> Redi.hget db, "hsnhash", "field"
        "Hello"
        iex> Redi.del db, "hsnhash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hsetnx(client // connect, key, field, value),
    do: query(client, [ "HSETNX", key, field, value ])

  @doc """
  ## HVALS key

  Get all the values in a hash

  Time complexity: O(N) where N is the size of the hash.

  More info: http://redis.io/commands/hvals

  ## Return value

  Multi-bulk reply: list of values in the hash, or an empty list when
  key does not exist.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "hvhash"
        "0"
        iex> Redi.hset db, "hvhash", "field1", "Hello"
        "1"
        iex> Redi.hset db, "hvhash", "field2", "World"
        "1"
        iex> Redi.hvals db, "hvhash"
        ["Hello", "World"]
        iex> Redi.del db, "hvhash"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def hvals(client // connect, key), do: query(client, [ "HVALS", key ])

  @doc """
  ## INCR key

  Increment the integer value of a key by one

  Time complexity: O(1)

  More info: http://redis.io/commands/incr

  ## Return value

  Integer reply: the value of key after the increment

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "ikey"
        "0"
        iex> Redi.set db, "ikey", "10"
        "OK"
        iex> Redi.incr db, "ikey"
        "11"
        iex> Redi.get db, "ikey"
        "11"
        iex> Redi.del db, "ikey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def incr(client // connect, key), do: query(client, [ "INCR", key ])

  @doc """
  ## INCRBY key incremenet

  Increment the integer value of a key by the given amount

  Time complexity: O(1)

  More info: http://redis.io/commands/incrby

  ## Return value

  Integer reply: the value of key after the increment

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "ibkey"
        "0"
        iex> Redi.set db, "ibkey", 10
        "OK"
        iex> Redi.incrby db, "ibkey", 5
        "15"
        iex> Redi.del db, "ibkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def incrby(client // connect, key, increment),
    do: query(client, [ "INCRBY", key, increment ])

  @doc """
  ## INCRBYFLOAT key incremenet

  Increment the float value of a key by the given amount

  Time complexity: O(1)

  More info: http://redis.io/commands/incrbyfloat

  ## Return value

  Bulk reply: the value of key after the increment

  ## Examples

        iex> db = Redi.connect
        iex> Redi.set db, "ifkey", 10.50
        "OK"
        iex> Redi.incrbyfloat db, "ifkey", 0.1
        "10.6"
        iex> Redi.set db, "ifkey", 5.0e3
        "OK"
        iex> Redi.incrbyfloat db, "ifkey", 2.0e2
        "5200"
        iex> Redi.del db, "ifkey"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def incrbyfloat(client // connect, key, increment),
    do: query(client, [ "INCRBYFLOAT", key, to_string(increment) ])

  @doc """
  ## INFO [section]

  Get information and statistics about the server

  More info: http://redis.io/commands/info

  ## Return value

  Bulk reply. As collection of text lines.

  """
  # For Redi.info
  def info(client // connect, section // nil)

  # For Redi.info client
  def info(client, section) when is_pid(client) and nil?(section),
    do: query(client, [ "INFO" ])

  # For Redi.info "section"
  def info(section, _) when not is_pid(section),
    do: connect |> query [ "INFO", section ]

  # For Redi.info client, "section"
  def info(client, section), do: query(client, [ "INFO", section ])

  @doc """
  ## KEYS pattern

  Find all keys matching the given pattern

  Time complexity: O(N) with N being the number of keys in the database,
  under the assumption that the key names in the database and the given
  pattern have limited length.

  More info: http://redis.io/commands/keys

  ## Return value

  Multi-bulk reply: list of keys matching pattern.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["one", "two", "three", "four"]
        "0"
        iex> Redi.mset db, ["one", 1, "two", 2, "three", 3, "four", 4]
        "OK"
        iex> Redi.keys db, "t??"
        ["two"]
        iex> Redi.del db, ["one", "two", "three", "four"]
        "4"
        iex> Redi.disconnect db
        :ok

  """
  def keys(client // connect, pattern), do: query(client, [ "KEYS", pattern ])

  @doc """
  ## LASTSAVE

  Get the UNIX timestamp of the last successful save to disk

  More info: http://redis.io/commands/lastsave

  ## Return value

  Integer reply. A UNIX time stamp.

  """
  def lastsave(client // connect), do: query(client, [ "LASTSAVE" ])

  @doc """
  ## LINDEX key index

  Get an element from a list by its index

  Time complexity: O(N) where N is the number of elements to traverse
  to get to the element at index. This makes asking for the first or
  the last element of the list O(1).

  More info: http://redis.io/command/lindex

  ## Return value

  Bulk reply: the requested element, or nil when index is out of range.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lilist"
        "0"
        iex> Redi.lpush db, "lilist", "World"
        "1"
        iex> Redi.lpush db, "lilist", "Hello"
        "2"
        iex> Redi.lindex db, "lilist", 0
        "Hello"
        iex> Redi.lindex db, "lilist", -1
        "World"
        iex> Redi.lindex db, "lilist", 3
        :undefined
        iex> Redi.del db, "lilist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def lindex(client // connect, key, index),
    do: query(client, [ "LINDEX", key, to_string(index) ])

  @doc """
  ## LINSERT key position pivot value

  Insert an element before or after another element in a list

  Time complexity: O(N) where N is the number of elements to traverse before
  seeing the value pivot. This means that inserting somewhere on the left
  end on the list (head) can be considered O(1) and inserting somewhere on
  the right end (tail) is O(N).

  More info: http://redis.io/command/linsert

  ## Return value

  Integer reply: the length of the list after the insert operation, or -1
  when the value pivot was not found.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lnlist"
        "0"
        iex> Redi.rpush db, "lnlist", "Hello"
        "1"
        iex> Redi.rpush db, "lnlist", "World"
        "2"
        iex> Redi.linsert db, "lnlist", "BEFORE", "World", "There"
        "3"
        iex> Redi.lrange db, "lnlist", 0, -1
        ["Hello", "There", "World"]
        iex> Redi.del db, "lnlist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def linsert(client // connect, key, position, pivot, value),
    do: query(client, [ "LINSERT", key, position, pivot, value ])

  @doc """
  ## LLEN key

  Get the length of a list

  Time complexity: O(1)

  More info: http://redis.io/command/llen

  ## Return value

  Integer reply, the length of the list at key.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lllist"
        "0"
        iex> Redi.lpush db, "lllist", "World"
        "1"
        iex> Redi.lpush db, "lllist", "Hello"
        "2"
        iex> Redi.llen db, "lllist"
        "2"
        iex> Redi.del db, "lllist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def llen(client // connect, key), do: query(client, [ "LLEN", key ])

  @doc """
  ## LPOP key

  Remove and get the first element in a list

  Time complexity: O(1)

  More info: http://redis.io/command/lpop

  ## Return value

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del "lplist"
        "0"
        iex> Redi.rpush db, "lplist", "one"
        "1"
        iex> Redi.rpush db, "lplist", "two"
        "2"
        iex> Redi.rpush db, "lplist", "three"
        "3"
        iex> Redi.lpop db, "lplist"
        "one"
        iex> Redi.lrange db, "lplist", 0, -1
        ["two", "three"]
        iex> Redi.del db, "lplist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def lpop(client // connect, key), do: query(client, [ "LPOP", key ])

  @doc """
  ## LPUSH key value [value ...]

  Prepend one or multiple values to a list

  Time complexity: O(1)

  More info: http://redis.io/command/lpush

  ## Return value

  Integer reply; the length of the list after the push operations.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lpslist"
        "0"
        iex> Redi.lpush db, "lpslist", "world"
        "1"
        iex> Redi.lpush db, "lpslist", "hello"
        "2"
        iex> Redi.lrange db, "lpslist", 0, -1
        ["hello", "world"]
        iex> Redi.del db, "lpslist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def lpush(client // connect, key, value) do
    if is_list(value) do
      query(client, [ "LPUSH" | [ key | value ] ])
    else
      query(client, [ "LPUSH", key, value ])
    end
  end

  @doc """
  ## LPUSHX key value

  Prepend a value to a list, only if the list exists

  Time complexity: O(1)

  More info: http://redis.io/command/lpushx

  ## Return value

  Integer reply; the length of the list after the push operations.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lxlist"
        "0"
        iex> Redi.lpush db, "lxlist", "World"
        "1"
        iex> Redi.lpush db, "lxlist", "Hello"
        "2"
        iex> Redi.lpushx db, "lxotherlist", "Hello"
        "0"
        iex> Redi.lrange db, "lxlist", 0, -1
        ["Hello", "World"]
        iex> Redi.lrange db, "lxotherlist", 0, -1
        []
        iex> Redi.del db, "lxlist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def lpushx(client // connect, key, value),
    do: query(client, [ "LPUSHX", key, value ])

  @doc """
  ## LRANGE key start stop

  Get a range of elements from a list

  Time complexity: O(S+N) where S is the start offseet and N is the number
  of elements in the specified range.

  More info: http://redis.io/command/lrange

  ## Return value

  Multi-bulk reply: list of elements in the specified range

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, "lrlist"
        "0"
        iex> Redi.rpush db, "lrlist", "one"
        "1"
        iex> Redi.rpush db, "lrlist", "two"
        "2"
        iex> Redi.rpush db, "lrlist", "three"
        "3"
        iex> Redi.lrange db, "lrlist", 0, 0
        ["one"]
        iex> Redi.lrange db, "lrlist", -3, 2
        ["one", "two", "three"]
        iex> Redi.lrange db, "lrlist", -100, 100
        ["one", "two", "three"]
        iex> Redi.lrange db, "lrlist", 5, 10
        []
        iex> Redi.del db, "lrlist"
        "1"
        iex> Redi.disconnect db
        :ok

  """
  def lrange(client // connect, key, range_start, range_stop),
    do: query(client, [ "LRANGE", key, range_start, range_stop ])

  @doc """
  ## LREM key count value

  Remove elements from a list

  Time complexity: O(N) where N is the length of the list.

  More info: http://redis.io/command/lrem

  ## Return value

  Integer reply: the number of removed elements.

  ## Examples

    iex> Redi.del "lmlist"
    "0"
    iex> Redi.rpush "lmlist", "hello"
    "1"
    iex> Redi.rpush "lmlist", "hello"
    "2"
    iex> Redi.rpush "lmlist", "foo"
    "3"
    iex> Redi.rpush "lmlist", "hello"
    "4"
    iex> Redi.lrem "lmlist", -2, "hello"
    "2"
    iex> Redi.lrange "lmlist", 0, -1
    ["hello", "foo"]
    iex> Redi.del "lmlist"
    "1"

  """
  def lrem(client // connect, key, count, value),
    do: query(client, [ "LREM", key, count, value ])

  @doc """
  ## LSET key index value

  Set the value of an element in a list by its index

  Time complexity: O(N) where N is the length of the list. Setting either
  the first or the last element of the list is O(1).

  More info: http://redis.io/command/lset

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

    iex> Redi.del "lslist"
    "0"
    iex> Redi.rpush "lslist", "one"
    "1"
    iex> Redi.rpush "lslist", "two"
    "2"
    iex> Redi.rpush "lslist", "three"
    "3"
    iex> Redi.lset "lslist", 0, "four"
    "OK"
    iex> Redi.lset "lslist", -2, "five"
    "OK"
    iex> Redi.lrange "lslist", 0, -1
    ["four", "five", "three"]
    iex> Redi.del "lslist"
    "1"

  """
  def lset(client // connect, key, index, value),
    do: query(client, [ "LSET", key, index, value ])

  @doc """
  ## LTRIM key start stop

  Trim a list to the specified range

  Time complexity: O(N) where N is the number of elements to be removed by
  the operation.

  More info: http://redis.io/command/ltrim

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

    iex> Redi.del "ltlist"
    "0"
    iex> Redi.rpush "ltlist", "one"
    "1"
    iex> Redi.rpush "ltlist", "two"
    "2"
    iex> Redi.rpush "ltlist", "three"
    "3"
    iex> Redi.ltrim "ltlist", 1, -1
    "OK"
    iex> Redi.lrange "ltlist", 0, -1
    ["two", "three"]
    iex> Redi.del "ltlist"
    "1"

  """
  def ltrim(client // connect, key, range_start, range_stop),
    do: query(client, [ "LTRIM", key, range_start, range_stop ])

  @doc """
  ## MGET key [key ...]

  Get the values of all the given keys

  Time complexity: O(N) where N is the number of keys to retrieve.

  More info: http://redis.io/commands/mget

  ## Return value

  Multi-bulk reply: list of values at the specified keys.

  ## Examples

    iex> Redi.del ["mgkey1", "mgkey2"]
    "0"
    iex> Redi.set "mgkey1", "Hello"
    "OK"
    iex> Redi.set "mgkey2", "World"
    "OK"
    iex> Redi.mget ["mgkey1", "mgkey2", "nonexisting"]
    ["Hello", "World", :undefined]
    iex> Redi.del ["mgkey1", "mgkey2"]
    "2"

  """
  def mget(client // connect, key) do
    if is_list(key) do
      query(client, [ "MGET" | key ])
    else
      query(client, [ "MGET", key ])
    end
  end

  @doc """
  ## MIGRATE host port key destination-db timeout [COPY] [REPLACE]

  Atomically transfer a key from a Redis instance to another one

  Time complexity: This command actually executes a DUMP+DEL in the source
  instance, and a RESTORE in the target instance. See the pages of these
  commands for time complexity. Also an O(N) data transfer between the two
  instances is performed.

  More info: http://redis.io/commands/migrate

  ## Return value

  Status code reply. The command returns OK on success.

  """
  def migrate(client // connect,
    host, port, key, destination_db, timeout, opt1 // nil, opt2 // nil)

  # Redi.migrate client, "host", "port", "key", "dest_db", "timeout", "opt1"
  def migrate(client, host, port, key, destination_db, timeout, opt1, opt2)
              when is_pid(client) and nil?(opt2),

    do: query(client, [
          "MIGRATE", host, port, key, destination_db, timeout, opt1 ])

  # Redi.migrate "host", "port", "key", "dest_db", "timeout", "opt1", "opt2"
  def migrate(host, port, key, destination_db, timeout, opt1, opt2, _)
              when not is_pid(host),

    do: connect |> query [
          "MIGRATE", host, port, key, destination_db, timeout, opt1, opt2 ]

  # Redi.migrate client, "host", "port", "key", "dest_db", "t_out", "o1", "o2"
  def migrate(client, host, port, key, destination_db, timeout, opt1, opt2),
    do: query(client, [
          "MIGRATE", host, port, key, destination_db, timeout, opt1, opt2 ])

  @doc """
  ## MONITOR

  Listen for all requests received by the server in real-time.

  More info: http://redis.io/commands/monitor

  ## Return value

  Non-standard return value. Just dumps the received commands in an infinite
  flow.

  """
  def monitor(client // connect), do: query(client, [ "MONITOR" ])

  @doc """
  ## MOVE key db

  Move a key to another database

  Time complexity: O(1)

  More info: http://redis.io/commands/move

  ## Return value

  Integer reply, specifically:

  * 1 if key was moved
  * 0 if key was not moved

  """
  def move(client // connect, key, db), do: query(client, [ "MOVE", key, db ])

  @doc """
  ## MSET key value [key value ...]

  Set multiple keys to multiple values

  Time complexity: O(N) where N is the numbers of keys to set.

  More info: http://redis.io/commands/mset

  ## Return value

  Status code reply: always OK since MSET can’t fai

  ## Examples

    iex> Redi.del ["mskey1", "mskey2"]
    "0"
    iex> Redi.mset ["mskey1", "Hello", "mskey2", "World"]
    "OK"
    iex> Redi.get "mskey1"
    "Hello"
    iex> Redi.get "mskey2"
    "World"
    iex> Redi.del ["mskey1", "mskey2"]
    "2"

  """
  def mset(client // connect, key, value // nil)

  # Redi.mset client, ["k1", "v1", "k2", "v2", "kn", "vn"]
  def mset(client, key_value, opt2) when is_pid(client) and nil?(opt2),
    do: query(client, [ "MSET" | key_value ])

  # For Redi.mset "k1", "v1"
  def mset(key, value, _) when not is_pid(key),
    do: connect |> query [ "MSET", key, value ]

  # For Redi.mset client, "k1", "v1"
  def mset(client, key, value),
    do: query(client, [ "MSET", key, value ])

  @doc """
  ## MSETNX key value [key value ...]

  Set multiple keys to multiple values, only if none of the keys exist

  Time complexity: O(N) where N is the numbers of keys to set.

  More info: http://redis.io/commands/msetnx

  ## Return value

  Integer reply, specifically:

  * 1 if all the keys were set.
  * 0 if no key was set (at least one key already existed).

  ## Examples

    iex> Redi.del ["mxkey1", "mxkey2"]
    "0"
    iex> Redi.msetnx ["mxkey1", "Hello", "mxkey2", "there"]
    "1"
    iex> Redi.msetnx ["mxkey2", "there", "mxkey3", "world"]
    "0"
    iex> Redi.mget ["mxkey1", "mxkey2", "mxkey3"]
    ["Hello", "there", :undefined]
    iex> Redi.del ["mxkey1", "mxkey2"]
    "2"

  """
  def msetnx(client // connect, key, value // nil)

  # For Redi.msetnx client, ["k1", "v1", "k2", "v2", "kn", "vn"]
  def msetnx(client, key_value, opt2) when is_pid(client) and nil?(opt2),
    do: query(client, [ "MSETNX" | key_value ])

  # For Redi.msetnx "k1", "v1"
  def msetnx(key, value, _) when not is_pid(key),
    do: connect |> query [ "MSETNX", key, value ]

  # For Redi.msetnx client, "k1", "v1"
  def msetnx(client, key, value),
    do: query(client, [ "MSETNX", key, value ])

  @doc """
  ## MULTI

  Mark the start of a transaction block

  More info: http://redis.io/commands/multi

  ## Return value

  Status code reply. Always OK.

  """
  def multi(client // connect), do: query(client, [ "MULTI" ])

  @doc """
  ## OBJECT subcommand [arguments [arguments ..]]

  Inspect the internals of Redis objects

  Time complexity: O(1) for all the currently implemented subcommands.

  More info: http://redis.io/commands/object

  ## Return value

  Different return values are used for different subcommands.

  * Subcommands refcount and idletime returns integers.
  * Subcommand encoding returns a bulk reply.

  If the object you try to inspect is missing, a null bulk reply is returned.

  ## Examples

    iex> Redi.del "oblist"
    "0"
    iex> Redi.lpush "oblist", "Hello World"
    "1"
    iex> Redi.object "refcount", "oblist"
    "1"
    iex> Redi.object "encoding", "oblist"
    "ziplist"
    iex> Redi.object "idletime", "oblist"
    "0"
    iex> Redi.del "oblist"
    "1"

  """
  def object(client // connect, subcommand, arguments) do
    if is_list(arguments) do
      query(client, [ "OBJECT" | [ subcommand | arguments ] ])
    else
      query(client, [ "OBJECT", subcommand, arguments ])
    end
  end

  @doc """
  ## PERSIST key

  Remove the expiration from a key

  Time complexity: O(1)

  More info: http://redis.io/commands/persist

  ## Return value

  Integer reply, specifically:

  * 1 if the timeout was removed.
  * 0 if key does not exist or does not have an associated timeout.

  ## Examples

    iex> Redi.set "prkey", "Hello"
    "OK"
    iex> Redi.expire "prkey", 10
    "1"
    iex> Redi.ttl "prkey"
    "10"
    iex> Redi.persist "prkey"
    "1"
    iex> Redi.ttl "prkey"
    "-1"

  """
  def persist(client // connect, key), do: query(client, [ "PERSIST", key ])

  @doc """
  ## PEXPIRE key milliseconds

  Set a key’s time to live in milliseconds

  Time complexity: O(1)

  More info: http://redis.io/commands/pexpire

  ## Return value

  Integer reply, specifically:

  * 1 if the timeout was set
  * 0 if key does not exist or the timeout could not be set

  """
  def pexpire(client // connect, key, milliseconds),
    do: query(client, [ "PEXPIRE", key, milliseconds ])

  @doc """
  ## PEXPIREAT key milliseconds-timestamp

  Set the expiration for a key as a UNIX timestamp specified in milliseconds

  Time complexity: O(1)

  More info: http://redis.io/commands/pexpireat

  ## Return value

  Integer reply, specifically:

  * 1 if the timout was set
  * 0 if key does not exist or the timeout could not be set (See: EXPIRE)

  """
  def pexpireat(client // connect, key, milliseconds_timestamp),
    do: query(client, [ "PEXPIREAT", key, milliseconds_timestamp ])

  @doc """
  ## PING

  Ping the server

  More info: http://redis.io/commands/ping

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

    iex> Redi.ping
    "PONG"

  """
  def ping(client // connect), do: query(client, [ "PING" ])

  @doc """
  ## PSETEX key milliseconds value

  Set the value and expiration in milliseconds of a key

  Time complexity: O(1)

  ## Examples

    iex> Redi.psetex "psekey", 1000, "Hello"
    "OK"
    iex> Redi.pttl "psekey"
    "1000"
    iex> Redi.get "psekey"
    "Hello"

  """
  def psetex(client // connect, key, milliseconds, value),
    do: query(client, [ "PSETEX", key, milliseconds, value ])

  @doc """
  ## PSUBSCRIBE pattern [pattern ...]

  Listen for messages published to channels matching the given patterns

  Time complexity: O(N) where N is the number of patterns the client is
  already subscribed to.

  More info: http://redis.io/commands/psubscribe

  Note: This function requires a different way to connect (see Redi.sub_connect)
        and an additional parameter not required in the original command.

  #FIXME

  """
  def psubscribe() do
  end

  @doc """
  ## PUBLISH channel message

  Post a message to a channel

  Time complexity: O(N+M) where N is the number of clients subscribed to
  the receiving channel and M is the total number of subscribed patterns
  (by any client).

  More info: http://redis.io/commands/publish

  ## Return value

  Integer reply. The number of clients that received the message.

  """
  def publish(client // connect, channel, message),
    do: query(client, [ "PUBLISH", channel, message ])

  @doc """
  ## PUBSUB CHANNELS [pattern]

  Inspect the state of the Pub/Sub subsystem

  Time complexity: O(N) for the CHANNELS subcommand, where N is the number
  of active channels, and assuming constant time pattern matching (relatively
  short channels and patterns). O(N) for the NUMSUB subcommand, where N is
  the number of requested channels. O(1) for the NUMPAT subcommand.

  More info: http://redis.io/commands/pubsub

  ## Return value

  Multi-bulk reply. A list of active channels, optionally matching the
  specified pattern.

  """
  # For Redi.pubsub_channels
  def pubsub_channels(client // connect, pattern // nil)

  # For Redi.pubsub_channels client
  def pubsub_channels(client, pattern) when is_pid(client) and nil?(pattern),
    do: query(client, [ "PUBSUB", "CHANNELS" ])

  # For Redi.pubsub_channels "pattern"
  def pubsub_channels(pattern, _) when not is_pid(pattern),
    do: connect |> query [ "PUBSUB", "CHANNELS", pattern ]

  # For Redi.pubsub_channels client, "pattern"
  def pubsub_channels(client, pattern),
    do: query(client, [ "PUBSUB", "CHANNELS", pattern ])

  @doc """
  ## PUBSUB NUMSUB [channel-1 ... channel-N]

  Inspect the state of the Pub/Sub subsystem

  Time complexity: O(N) for the CHANNELS subcommand, where N is the number
  of active channels, and assuming constant time pattern matching (relatively
  short channels and patterns). O(N) for the NUMSUB subcommand, where N is
  the number of requested channels. O(1) for the NUMPAT subcommand.

  More info: http://redis.io/commands/pubsub

  ## Return value

  Multi-bulk reply. A list of channles and number of subscribers for every
  channel. The format is channel, count, channel, cout, ..., so the list is
  flat. The order in which the channels are listed is the same as the order
  of the channels specified in the command call.

  Note that it is valid to call this command without channels. In this case
  it will just return an empty list.

  """
  # For Redi.pubsub_numsub
  def pubsub_numsub(client // connect, channel // nil)

  # For Redi.pubsub_numsub client
  def pubsub_numsub(client, channel) when is_pid(client) and nil?(channel),
    do: query(client, [ "PUBSUB", "NUMSUB" ])

  # For Redi.pubsub_numsub ["channel-1", "channel-2", "channel-n"]
  def pubsub_numsub(channel, _) when is_list(channel),
    do: connect |> query [ "PUBSUB" | [ "NUMSUB" | channel ] ]

  # For Redi.pubsub_numsub "channel"
  def pubsub_numsub(channel, _) when not is_pid(channel),
    do: connect |> query [ "PUBSUB", "NUMSUB", channel ]

  # For Redi.pubsub_numsub client, ["channel-1", "channel-2", "channel-n"]
  def pubsub_numsub(client, channel) when is_list(channel),
    do: query(client, [ "PUBSUB" | [ "NUMSUB" | channel ] ])

  # For Redi.pubsub_numsub client, "channel"
  def pubsub_numsub(client, channel),
    do: query(client, [ "PUBSUB", "NUMSUB", channel ])

  @doc """
  ## PUBSUB NUMPAT

  Inspect the state of the Pub/Sub subsystem

  Time complexity: O(N) for the CHANNELS subcommand, where N is the number
  of active channels, and assuming constant time pattern matching (relatively
  short channels and patterns). O(N) for the NUMSUB subcommand, where N is
  the number of requested channels. O(1) for the NUMPAT subcommand.

  More info: http://redis.io/commands/pubsub

  ## Return value

  Integer reply. The number of patterns all the clients are subscribed to.

  """
  def pubsub_numpat(client // connect), do: query(client, [ "PUBSUB", "NUMPAT" ])

  @doc """
  ## PUNSUBSCRIBE [pattern [pattern ...]]

  Stop listening for messages posted to channels matching the given patterns

  Time complexity: O(N+M) where N is the number of patterns the client is
  already subscribed and M is the number of total patterns subscribed in
  the system (by any client).

  More info: http://redis.io/commands/punsubscribe

  #FIXME

  """
  def punsubscribe(client // sub_connect, pattern // nil)

  # For Redi.punsubscribe client
  def punsubscribe(client, pattern) when is_pid(client) and nil?(pattern) do
  end

  # For Redi.punsubscribe client, "pattern"
  def punsubscribe(client, pattern) when is_pid(client) and not nil?(pattern) do
  end

  @doc """
  ## PTTL key

  Get the time to live fo a key in milliseconds

  Time complexity: O(1)

  More info: http://redis.io/commands/pttl

  ## Return value

  Integer reply: Time to live in milliseconds or -1 when key does not exist
  or does not have a timeout.

  """
  def pttl(client // connect, key), do: query(client, [ "PTTL", key ])

  @doc """
  ## RANDOMKEY

  Return a random key from the keyspace

  Time complexity: O(1)

  More info: http://redis.io/commands/randomkey

  ## Return value

  Bulk reply: the random key, or nil when the database is empty.

  """
  def randomkey(client // connect), do: query(client, [ "RANDOMKEY" ])

  @doc """
  ## RENAME key newkey

  Rename a key

  Time complexity: O(1)

  More info: http://redis.io/commands/rename

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

    iex> Redi.del "otherrkey"
    "0"
    iex> Redi.set "rkey", "Hello"
    "OK"
    iex> Redi.rename "rkey", "otherrkey"
    "OK"
    iex> Redi.get "otherrkey"
    "Hello"
    iex> Redi.del "otherrkey"
    "1"

  """
  def rename(client // connect, key, newkey),
    do: query(client, [ "RENAME", key, newkey ])

  @doc """
  ## RENAMENX key newkey

  Rename a key, only if the new key does not exist

  Time complexity: O(1)

  More info: http://redis.io/commands/renamenx

  ## Return value

  Integer reply, specifically:

  * 1 if key was renamed to newkey.
  * 0 if newkey already exists.

  ## Examples

    iex> Redi.del "rnxkey"
    "0"
    iex> Redi.set "rnxkey", "Hello"
    "OK"
    iex> Redi.set "otherrnxkey", "World"
    "OK"
    iex> Redi.renamenx "rnxkey", "otherrnxkey"
    "0"
    iex> Redi.get "otherrnxkey"
    "World"
    iex> Redi.del "rnxkey"
    "1"

  """
  def renamenx(client // connect, key, newkey),
    do: query(client, [ "RENAMENX", key, newkey ])

  @doc """
  ## RESTORE key ttl serialized-value

  Create a key using the provided serialized value, previously obtained
  using DUMP

  Time complexity: O(1) to create the new key and additional O(N*M) to
  reconstruct the serialized value, where N is the number of Redis objects
  composing the value and M their average size. For small string values the
  time complexity is thus O(1)+O(1*M) where M is small, so simply O(1).
  However for sorted set values the complexity is O(N*M*log(N)) because
  inserting values into sorted sets is O(log(N)).

  More info: http://redis.io/commands/restore

  ## Examples

    iex> Redi.del "rskey"
    "0"
    iex> Redi.set "rskey", 7
    "OK"
    iex> Redi.dump "rskey"
    <<0, 192, 7, 6, 0, 226, 32, 32, 34, 118, 254, 242, 1>>
    iex> Redi.del "rskey"
    "1"
    iex> Redi.get "rskey"
    :undefined
    iex> Redi.restore "rskey", 0, <<0, 192, 7, 6, 0, 226, 32, 32, 34, 118, 254, 242, 1>>
    "OK"
    iex> Redi.get "rskey"
    "7"
    iex> Redi.del "rskey"
    "1"

  """
  def restore(client // connect, key, ttl, serialized_value),
    do: query(client, [ "RESTORE", key, ttl, serialized_value ])

  @doc """
  ## RPOP key

  Remove and get the last element in a list

  Time complexity: O(1)

  More info: http://redis.io/commands/rpop

  ## Return value

  Bulk reply: the value of the last element, or nil when key does not exist.

  ## Examples

    iex> Redi.del "rpplist"
    "0"
    iex> Redi.rpush "rpplist", "one"
    "1"
    iex> Redi.rpush "rpplist", "two"
    "2"
    iex> Redi.rpush "rpplist", "three"
    "3"
    iex> Redi.rpop "rpplist"
    "three"
    iex> Redi.lrange "rpplist", 0, -1
    ["one", "two"]
    iex> Redi.del "rpplist"
    "1"

  """
  def rpop(client // connect, key), do: query(client, [ "RPOP", key ])

  @doc """
  ## RPOPLPUSH source destination

  Remove the last element in a list, append it to another list and return it.

  Time complexity: O(1)

  More info: http://redis.io/commands/rpoplpush

  ## Return value

  Bulk reply. The element being popped and pushed.

  ## Examples

    iex> Redi.del ["rpllist", "rplotherlist"]
    "0"
    iex> Redi.rpush "rpllist", "one"
    "1"
    iex> Redi.rpush "rpllist", "two"
    "2"
    iex> Redi.rpush "rpllist", "three"
    "3"
    iex> Redi.rpoplpush "rpllist", "rplotherlist"
    "three"
    iex> Redi.lrange "rpllist", 0, -1
    ["one", "two"]
    iex> Redi.lrange "rplotherlist", 0, -1
    ["three"]
    iex> Redi.del ["rpllist", "rplotherlist"]
    "2"

  """
  def rpoplpush(client // connect, source, destination),
    do: query(client, [ "RPOPLPUSH", source, destination ])

  @doc """
  ## RPUSH key value [value ...]

  Append one or multiple values to a list

  Time complexity: O(1)

  More info: http://redis.io/commands/rpush

  ## Return value

  Integer reply: the length of the list after the push operation.

  ## Examples

    iex> Redi.del "rplist"
    "0"
    iex> Redi.rpush "rplist", "hello"
    "1"
    iex> Redi.rpush "rplist", "world"
    "2"
    iex> Redi.lrange "rplist", 0, -1
    ["hello", "world"]
    iex> Redi.del "rplist"
    "1"

  """
  def rpush(client // connect, key, value) do
    if is_list(value) do
      query(client, [ "RPUSH" | [ key | value ] ])
    else
      query(client, [ "RPUSH", key, value ])
    end
  end

  @doc """
  ## RPUSHX key value

  Append a value to a list, only if the list exists

  Time complexity: O(1)

  More info: http://redis.io/commands/rpushx

  ## Return value

  Integer reply: the length of the list after the push operation.

  ## Examples

    iex> Redi.del "rpxlist"
    "0"
    iex> Redi.rpush "rpxlist", "Hello"
    "1"
    iex> Redi.rpushx "rpxlist", "World"
    "2"
    iex> Redi.rpushx "rpxotherlist", "World"
    "0"
    iex> Redi.lrange "rpxlist", 0, -1
    ["Hello", "World"]
    iex> Redi.lrange "rpxotherlist", 0, -1
    []
    iex> Redi.del "rpxlist"
    "1"

  """
  def rpushx(client // connect, key, value),
    do: query(client, [ "RPUSHX", key, value ])

  @doc """
  ## SADD key member [member ...]

  Add one or more members to a set

  Time complexity: O(N) where N is the number of members to be added.

  More info: http://redis.io/commands/sadd

  ## Return value

  Integer reply: the number of elements that were added to the set, not
  including all the elements already present into the set.

  ## Examples

    iex> Redi.del "sdset"
    "0"
    iex> Redi.sadd "sdset", "Hello"
    "1"
    iex> Redi.sadd "sdset", "World"
    "1"
    iex> Redi.smembers "sdset"
    ["Hello", "World"]
    iex> Redi.del "sdset"
    "1"

  """
  def sadd(client // connect, key, member) do
    if is_list(member) do
      query(client, [ "SADD" | [ key | member ] ])
    else
      query(client, [ "SADD", key, member ])
    end
  end

  @doc """
  ## SAVE

  Synchronously save the dataset to disk

  More info: http://redis.io/commands/save

  ## Return value

  Status code reply. The command returns OK on success.

  """
  def save(client // connect), do: query(client, [ "SAVE" ])

  @doc """
  ## SCARD key

  Get the number of members in a set

  Time complexity: O(1)

  More info: http://redis.io/commands/scard

  ## Return value

  Integer reply: the cardinality (number of elements) of the set, or 0
  if key does not exist.

  ## Examples

    iex> Redi.del "scset"
    "0"
    iex> Redi.sadd "scset", "Hello"
    "1"
    iex> Redi.sadd "scset", "World"
    "1"
    iex> Redi.scard "scset"
    "2"
    iex> Redi.del "scset"
    "1"

  """
  def scard(client // connect, key), do: query(client, [ "SCARD", key ])

  @doc """
  ## SCRIPT EXISTS script

  Check existence of scripts in the script cache

  Time complexity: O(N) with N being the number of scripts to check (so
  checking a single script is an O(1) operation).

  More info: http://redis.io/commands/script-exists

  ## Return value

  Multi-bulk reply. The command returns an array of integers that correspond
  to the specified SHA1 digest arguments. For every corresponding SHA1 digest
  of a script that actually exists in the script cache, a 1 is returned,
  otherwise 0 is returned.

  ## Examples

    iex> Redi.script_load "return 1"
    "e0e1f9fabfc9d4800c877a703b823ac0578ff8db"
    iex> Redi.script_exists "e0e1f9fabfc9d4800c877a703b823ac0578ff8db"
    ["1"]

  """
  def script_exists(client // connect, script) do
    if is_list(script) do
      query(client, [ "SCRIPT" | [ "EXISTS" | script ] ])
    else
      query(client, [ "SCRIPT", "EXISTS", script ])
    end
  end

  @doc """
  ## SCRIPT FLUSH

  Remove all the scripts from the script cache

  Time complexity: O(N) with N being the number of scripts in cache.

  More info: http://redis.io/commands/script-flush

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def script_flush(client // connect), do: query(client, [ "SCRIPT", "FLUSH" ])

  @doc """
  ## SCRIPT KILL

  Kill the script currently in execution

  Time complexity: O(1)

  More info: http://redis.io/commands/script-kill

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def script_kill(client // connect), do: query(client, [ "SCRIPT", "KILL" ])

  @doc """
  ## SCRIPT LOAD script

  Load the specified Lua script in the script cache

  Time complexity: O(N) with N being the length in bytes of the script body.

  More info: http://redis.io/commands/script-load

  ## Return value

  Bulk reply. This command returns the SHA1 digest of the script added into
  the script cache.

  """
  def script_load(client // connect, script),
    do: query(client, [ "SCRIPT" , "LOAD", script ])

  @doc """
  ## SDIFF key [key ...]

  Subtract multiple sets

  Time complexity: O(N) where N is the total number of elements in all
  given sets.

  More info: http://redis.io/commands/sdiff

  ## Return value

  Multi-bulk reply: list with members of the resulting set.

  ## Example

        iex> db = Redi.connect
        iex> Redi.del db, ["sdkey1", "sdkey2"]
        "0"
        iex> Redi.sadd db, "sdkey1", "a"
        "1"
        iex> Redi.sadd db, "sdkey1", "b"
        "1"
        iex> Redi.sadd db, "sdkey1", "c"
        "1"
        iex> Redi.sadd db, "sdkey2", "c"
        "1"
        iex> Redi.sadd db, "sdkey2", "d"
        "1"
        iex> Redi.sadd db, "sdkey2", "e"
        "1"
        iex> Redi.sdiff db, ["sdkey1", "sdkey2"]
        ["a", "b"]
        iex> Redi.del db, ["sdkey1", "sdkey2"]
        "2"
        iex> Redi.disconnect db
        :ok

  """
  def sdiff(client // connect, key) do
    if is_list(key) do
      query(client, [ "SDIFF" | key ])
    else
      query(client, [ "SDIFF", key ])
    end
  end

  @doc """
  ## SELECT index

  Change the selected database for the current connection

  More info: http://redis.io/commands/select

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def select(client // connect, index), do: query(client, [ "SELECT", index ])

  @doc """
  ## SET key value [EX seconds] [PX milliseconds] [NX|XX]

  Set the string value of a key

  Time complexity: O(1)

  More info: http://redis.io/commands/set

  ## Return value

  Status code reply: OK if SET was executed correctly. Null multi-bulk reply:
  A Null Bulk Reply is returned if the SET operation was not performed because
  the user specified the NX or XX option but the condition was not met.

  ## Examples

    iex> Redi.del "skey"
    "0"
    iex> Redi.set "skey", "Hello"
    "OK"
    iex> Redi.get "skey"
    "Hello"
    iex> Redi.del "skey"
    "1"

  """
  # Crazy long. There must be a better way to do this :)
  def set(client // connect, key, value, opt1 // nil, opt2 // nil, opt3 // nil)

  # For Redi.set client, "key", "value"
  #   or, Redi.set "key", "value"
  def set(client, key, value, opt1, opt2, opt3) when nil?(opt1) and
          nil?(opt2) and nil?(opt3) and is_pid(client),

    do: query(client, [ "SET", key, to_string(value) ])

  # For Redi.set client, "key", "value", "opt1"
  #   or, Redi.set client, "key", "value", ["opt1", "value"]
  # That means, this should also work with
  #   Redi.set client, "key", "value", ["opt1", "value", "opt2"]
  #   or, Redi.set client, "key", "value", ["opt1", "v1", "opt2", "v2", "opt3"]
  #   (The same applies to all the following functions.)
  # It does NOT make sense to pass both ["EX", seconds, "PX", milliseconds] but
  #   since you are allowed to shoot yourself in the foot in the redis-cli,
  #   you should be allowed to do it here as well here ;)
  def set(client, key, value, opt1, opt2, opt3) when is_pid(client) and
          nil?(opt2) and nil?(opt3) do

    if is_list(opt1) do
      query(client, [ "SET" | [ key | [ to_string(value) | opt1 ] ] ])
    else
      query(client, [ "SET", key, to_string(value), opt1 ])
    end

  end

  # For Redi.set client, "key", "value", ["opt1", "value"], "opt2"
  def set(client, key, value, opt1, opt2, opt3) when is_pid(client) and
          is_list(opt1) and nil?(opt3),

    do: query(client,
          [ "SET" | [ key | [ to_string(value) | opt1 ++ [ opt2 ] ] ] ])

  # For Redi.set client, "key", "value", "opt1", ["opt2", "value"]
  def set(client, key, value, opt1, opt2, opt3) when is_pid(client) and
          is_list(opt2) and nil?(opt3),

    do: query(client,
          [ "SET" | [ key | [ to_string(value) | [ opt1 ] ++ opt2 ] ] ])

  # For Redi.set "key", "value", "opt1"
  #   or, Redi.set "key", "value", ["opt1", "value"]
  def set(key, value, opt1, opt2, opt3, _) when not is_pid(key) and
          nil?(opt2) and nil?(opt3) do

    if is_list(opt1) do
      connect |> query [ "SET" | [ key | [ to_string(value) | opt1 ] ] ]
    else
      connect |> query [ "SET", key, to_string(value), opt1 ]
    end

  end

  # For Redi.set "key", "value", ["opt1", "value"], "opt2"
  def set(key, value, opt1, opt2, opt3, _) when not is_pid(key) and
          is_list(opt1) and nil?(opt3),

    do: connect |> query [
          "SET" | [ key | [ to_string(value) | opt1 ++ [ opt2 ] ] ] ]

  # For Redi.set "key", "value", "opt1", ["opt2", "value"]
  def set(key, value, opt1, opt2, opt3, _) when not is_pid(key) and
          is_list(opt2) and nil?(opt3),

    do: connect |> query [
          "SET" | [ key | [ to_string(value) | [ opt1 ] ++ opt2 ] ] ]

  # For Redi.set "key", "value", ["opt1", "v1"], ["opt2", "v2"], "opt3"
  def set(key, value, opt1, opt2, opt3, _) when not is_pid(key) and
          is_list(opt1) and is_list(opt2),

    do: connect |> query [
          "SET" | [ key | [ to_string(value) | opt1 ++ opt2 ++ [ opt3 ] ] ] ]

  # For Redi.set client, "key", "value", ["opt1", "v1"], ["opt2", "v2"], "opt3"
  def set(client, key, value, opt1, opt2, opt3),
    do: query(client,
        [ "SET" | [ key | [ to_string(value) | opt1 ++ opt2 ++ [ opt3 ] ] ] ])

  @doc """
  ## SETBIT key offset value

  Sets or clears the bit at offset in the string value stored at key

  Time complexity: O(1)

  More info: http://redis.io/commands/setbit

  ## Return value

  Integer reply: the original bit value store at offset.

  ## Examples

    iex> Redi.del "sbkey"
    "0"
    iex> Redi.setbit "sbkey", 7, 1
    "0"
    iex> Redi.setbit "sbkey", 7, 0
    "1"
    iex> Redi.get "sbkey"
    <<0>>
    iex> Redi.del "sbkey"
    "1"

  """
  def setbit(client // connect, key, offset, value),
    do: query(client, [ "SETBIT", key, offset, value ])

  @doc """
  ## SETEX key seconds value

  Set the value and expiration of a key

  Time complexity: O(1)

  More info: http://redis.io/commands/setex

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  ## Examples

    iex> Redi.setex "sxkey", 10, "Hello"
    "OK"
    iex> Redi.ttl "sxkey"
    "10"
    iex> Redi.get "sxkey"
    "Hello"

  """
  def setex(client // connect, key, seconds, value),
    do: query(client, [ "SETEX", key, seconds, value ])

  @doc """
  ## SETNX key value

  Set the value of a key, only if the key does not exist

  Time complexity: O(1)

  More info: http://redis.io/commands/setnx

  ## Return value

  Integer reply, specifically:

  * 1 if the key was set
  * 0 if the key was not set

  ## Examples

    iex> Redi.del "snxkey"
    "0"
    iex> Redi.setnx "snxkey", "Hello"
    "1"
    iex> Redi.setnx "snxkey", "World"
    "0"
    iex> Redi.get "snxkey"
    "Hello"
    iex> Redi.del "snxkey"
    "1"

  """
  def setnx(client // connect, key, value),
    do: query(client, [ "SETNX", key, value ])

  @doc """
  ## SETRANGE key offset value

  Overwrite part of a string at key starting at the specified offset

  Time complexity: O(1), not counting the time taken to copy the new string
  in place. Usually, this string is very small so the amortized complexity
  is O(1). Otherwise, complexity is O(M) with M being the length of the
  value argument.

  More info: http://redis.io/commands/setrange

  ## Return value

  Integer reply: the length of the string after it was modified by the command.

  ## Examples

    iex> Redi.del "srkey"
    "0"
    iex> Redi.set "srkey", "Hello World"
    "OK"
    iex> Redi.setrange "srkey", 6, "Redis"
    "11"
    iex> Redi.get "srkey"
    "Hello Redis"
    iex> Redi.del "srkey"
    "1"

  """
  def setrange(client // connect, key, offset, value),
    do: query(client, [ "SETRANGE", key, offset, value ])

  @doc """
  ## SHUTDOWN [NOSAVE] [SAVE]

  Synchronously save the dataset to disk and then shut down the server

  More info: http://redis.io/commands/shutdown

  """
  # For Redi.shutdown
  def shutdown(client // connect, option // nil)

  # For Redi.shutdown client
  def shutdown(client, option) when is_pid(client) and nil?(option),
    do: query(client, [ "SHUTDOWN" ])

  # For Redi.shutdown "option"
  def shutdown(option, _) when not is_pid(option),
    do: connect |> query [ "SHUTDOWN", option ]

  # For Redi.shutdown client, "option"
  def shutdown(client, option),
    do: query(client, [ "SHUTDOWN", option ])

  @doc """
  ## SINTER key [key ...]

  Intersect muliple sets

  Time complexity: O(N*M) worst case where N is the cardinality of the
  smallest set and M is the number of sets.

  More info: http://redis.io/commands/sinter

  ## Return value

  Multi-bulk reply. List with members of the resulting set.

  ## Examples

    iex> Redi.del ["sntrkey1", "sntrkey2"]
    "0"
    iex> Redi.sadd "sntrkey1", "a"
    "1"
    iex> Redi.sadd "sntrkey1", "b"
    "1"
    iex> Redi.sadd "sntrkey1", "c"
    "1"
    iex> Redi.sadd "sntrkey2", "c"
    "1"
    iex> Redi.sadd "sntrkey2", "d"
    "1"
    iex> Redi.sadd "sntrkey2", "e"
    "1"
    iex> Redi.sinter ["sntrkey1", "sntrkey2"]
    ["c"]
    iex> Redi.del ["sntrkey1", "sntrkey2"]
    "2"

  """
  def sinter(client // connect, key) do
    if is_list(key) do
      query(client, [ "SINTER" | key ])
    else
      query(client, [ "SINTER", key ])
    end
  end

  @doc """
  ## SINTERSTORE destination key [key ...]

  Intersect multiple sets and store the resulting set in a key

  Time complexity: O(N*M) worst case where N is the cardinality of the
  smallest set and M is the number of sets.

  More info: http://redis.io/commands/sinterstore

  ## Return value

  Integer reply. The number of elements in the resulting set.

  """
  def sinterstore(client // connect, destination, key) do
    if is_list(key) do
      query(client, [ "SINTERSTORE" | [ destination | key ] ])
    else
      query(client, [ "SINTERSTORE", destination, key ])
    end
  end

  @doc """
  ## SISMEMBER key member

  Determine if a given value is a member of a set

  Time complexity: O(1)

  More info: http://redis.io/commands/sismember

  ## Return value

  Integer reply, specifically:

  * 1 if the element is a member of the set
  * 0 if the element is not a member of the set, or if key does not exist

  ## Examples

    iex> Redi.del "smbset"
    "0"
    iex> Redi.sadd "smbset", "one"
    "1"
    iex> Redi.sismember "smbset", "one"
    "1"
    iex> Redi.sismember "smbset", "two"
    "0"
    iex> Redi.del "smbset"
    "1"

  """
  def sismember(client // connect, key, member),
    do: query(client, [ "SISMEMBER", key, member ])

  @doc """
  ## SLAVEOF host port

  Make the server a slave of another instance, or promote it as master

  More info: http://redis.io/commands/slaveof

  ## Return value

  [Status code reply](http://redis.io/topics/protocol#status-reply)

  """
  def slaveof(client // connect, host, port),
    do: query(client, [ "SLAVEOF", host, port ])

  @doc """
  ## SLOWLOG subcommand [argument]

  Manages the Redis slow queries log

  More info: http://redis.io/commands/slowlog

  """
  def slowlog(client // connect, subcommand, argument // nil)

  # For Redi.slowlog client, "subcommand"
  #   or, Redi.slowlog "subcommand"
  def slowlog(client, subcommand, argument) when is_pid(client) and
              nil?(argument),

    do: query(client, [ "SLOWLOG", subcommand ])

  # For Redi.slowlog "subcommand", "argument"
  def slowlog(subcommand, argument, _) when not is_pid(subcommand),
    do: connect |> query [ "SLOWLOG", subcommand, argument ]

  # For Redi.slowlog client, "subcommand", "argument"
  def slowlog(client, subcommand, argument),
    do: query(client, [ "SLOWLOG", subcommand, argument ])

  @doc """
  ## SMEMBERS key

  Get all the members in a set

  Time complexity: O(N) where N is the set cardinality.

  More info: http://redis.io/commands/smembers

  ## Return value

  Multi-bulk reply: all elements of the set.

  ## Examples

    iex> Redi.del "smset"
    "0"
    iex> Redi.sadd "smset", "Hello"
    "1"
    iex> Redi.sadd "smset", "World"
    "1"
    iex> Redi.smembers "smset"
    ["Hello", "World"]
    iex> Redi.del "smset"
    "1"

  """
  def smembers(client // connect, key), do: query(client, [ "SMEMBERS", key ])

  @doc """
  ## SMOVE source destination member

  Move a member from one set to another

  Time complexity: O(1)

  More info: http://redis.io/commands/smove

  ## Return value

  Integer reply, specifically:

  * 1 if the element is moved
  * 0 if the element is not a member of source and no operation was performed

  ## Examples

    iex> Redi.del ["smvset", "smvotherset"]
    "0"
    iex> Redi.sadd "smvset", "one"
    "1"
    iex> Redi.sadd "smvset", "two"
    "1"
    iex> Redi.sadd "smvotherset", "three"
    "1"
    iex> Redi.smove "smvset", "smvotherset", "two"
    "1"
    iex> Redi.smembers "smvset"
    ["one"]
    iex> Redi.smembers "smvotherset"
    ["two", "three"]
    iex> Redi.del ["smvset", "smvotherset"]
    "2"

  """
  def smove(client // connect, source, destination, member),
    do: query(client, [ "SMOVE", source, destination, member ])

  @doc """
  ## SPOP key

  Remove and return a random member from a set

  Time complexity: O(1)

  More info: http://redis.io/commands/spop

  ## Return value

  Bulk reply. The removed element, or nil when key does not exist.

  """
  def spop(client // connect, key), do: query(client, [ "SPOP", key ])

  @doc """
  ## SRANDMEMBER key count

  Get one or multiple random members from a set

  Time complexity: Without the count argument O(1), otherwise O(N) where N is
  the absolute value of the passed count.

  More info: http://redis.io/commands/srandmember

  """
  def srandmember(client // connect, key, count // 1),
    do: query(client, [ "SRANDMEMBER", key, count ])

  @doc """
  ## STRLEN key

  Get the length of the value stored in a key

  Time complexity: O(1)

  More info: http://redis.io/commands/strlen

  ## Return value

  Integer reply: the length of the string at key, or 0 when key does not exist.

  ## Examples

    iex> Redi.del "slkey"
    "0"
    iex> Redi.set "slkey", "Hello world"
    "OK"
    iex> Redi.strlen "slkey"
    "11"
    iex> Redi.strlen "nonexisting"
    "0"
    iex> Redi.del "slkey"
    "1"

  """
  def strlen(client // connect, key), do: query(client, [ "STRLEN", key ])

  @doc """
  ## SDIFFSTORE destination key [key ...]

  Subtract multiple sets and store the resulting set in a key

  Time complexity: O(N) where N is the total number of elements in all
  given sets.

  More info: http://redis.io/commands/sdiffstore

  ## Return value

  Integer reply. The number of elements in the resulting set.

  """
  def sdiffstore(client // connect, destination, key) do
    if is_list(key) do
      query(client, [ "SDIFFSTORE" | [ destination | key ] ])
    else
      query(client, [ "SDIFFSTORE", destination, key ])
    end
  end

  @doc """
  ## SREM key member [member ...]

  Remove one or more members from a set

  Time complexity: O(N) where N is the number of members to be removed.

  More info: http://redis.io/commands/srem

  ## Return value

  Integer reply. The number of members that were removed from the set,
  not including non existing members.

  ## Examples

    iex> Redi.del "srmset"
    "0"
    iex> Redi.sadd "srmset", "one"
    "1"
    iex> Redi.sadd "srmset", "two"
    "1"
    iex> Redi.sadd "srmset", "three"
    "1"
    iex> Redi.srem "srmset", "one"
    "1"
    iex> Redi.srem "srmset", "four"
    "0"
    iex> Redi.smembers "srmset"
    ["two", "three"]
    iex> Redi.del "srmset"
    "1"

  """
  def srem(client // connect, key, member) do
    if is_list(member) do
      query(client, [ "SREM" | [ key | member ] ])
    else
      query(client, [ "SREM", key, member ])
    end
  end

  @doc """
  ## SUBSCRIBE channel [channel ...]

  Listen for messages published to the given channels

  Time complexity: O(N) where N is the number of channels to subscribe to.

  More info: http://redis.io/commands/subscribe

  Note: This function requires a different way to connect (see Redi.sub_connect)
        and an additional parameter not required in the original command.

  #FIXME

  """
  def subscribe() do
  end

  @doc """
  ## SUNION key [key ...]

  Add multiple sets

  Time complexity: O(N) where N is the total number of elements in
  all given sets.

  More info: http://redis.io/commands/sunion

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["snkey1", "snkey2"]
        "0"
        iex> Redi.sadd db, "snkey1", "a"
        "1"
        iex> Redi.sadd db, "snkey1", "b"
        "1"
        iex> Redi.sadd db, "snkey1", "c"
        "1"
        iex> Redi.sadd db, "snkey2", "c"
        "1"
        iex> Redi.sadd db, "snkey2", "d"
        "1"
        iex> Redi.sadd db, "snkey2", "e"
        "1"
        iex> Redi.sunion db, ["snkey1", "snkey2"]
        ["a", "b", "c", "d", "e"]
        iex> Redi.del db, ["snkey1", "snkey2"]
        "2"
        iex> Redi.disconnect db
        :ok

  """
  def sunion(client // connect, key) do
    if is_list(key) do
      query(client, [ "SUNION" | key ])
    else
      query(client, [ "SUNION", key ])
    end
  end

  @doc """
  ## SUNIONSTORE destination key [key ...]

  Add multiple sets and store the resulting set in a key

  Time complexity: O(N) where N is the total number of elements in all
  given sets.

  More info: http://redis.io/commands/sunionstore

  ## Return value

  Integer reply. The number of elements in the resulting set.

  """
  def sunionstore(client // connect, destination, key) do
    if is_list(key) do
      query(client, [ "SUNIONSTORE" | [ destination | key ] ])
    else
      query(client, [ "SUNIONSTORE", destination, key ])
    end
  end

  @doc """
  ## SYNC

  Internal command used for replication

  More info: http://redis.io/commands/sync

  """
  def sync(client // connect), do: query(client, [ "SYNC" ])

  @doc """
  ## TIME

  Return the current server time

  Time complexity: O(1)

  More info: http://redis.io/commands/time

  ## Return value

  Multi-bulk reply, specifically:

  A multi-bulk reply containing two elements:

  * Unix time in seconds
  * microseconds

  """
  def time(client // connect), do: query(client, [ "TIME" ])

  @doc """
  ## TTL key

  Get the time to live for a key

  Time complexity: O(1)

  More info: http://redis.io/commands/ttl

  ## Return value

  Integer reply: TTL in seconds, -2 when key does not exist of -1 when key
  does not have a timeout.

  ## Examples

    iex> Redi.set "ttkey", "Hello"
    "OK"
    iex> Redi.expire "ttkey", 10
    "1"
    iex> Redi.ttl "ttkey"
    "10"

  """
  def ttl(client // connect, key), do: query(client, [ "TTL", key ])

  @doc """
  ## TYPE key

  Determine the type stored at key

  Time complexity: O(1)

  More info: http://redis.io/commands/type

  ## Return value

  Status code reply: type of key, or none when key does not exist.

  ## Examples

    iex> Redi.set "tykey", "value"
    "OK"
    iex> Redi.lpush "tykey2", "value"
    "1"
    iex> Redi.sadd "tykey3", "value"
    "1"
    iex> Redi.type "tykey"
    "string"
    iex> Redi.type "tykey2"
    "list"
    iex> Redi.type "tykey3"
    "set"
    iex> Redi.del ["tykey", "tykey2", "tykey3"]
    "3"

  """
  def type(client // connect, key), do: query(client, [ "TYPE", key ])

  @doc """
  ## SORT key [BY patter] [LIMIT offset count] [GET pattern [GET pattern ...]]
  [ASC|DESC] [ALPHA] [STORE destination]

  Sort the elements in a list, set or sorted set

  Time complexity: O(N+M*log(M)) where N is the number of elements in the
  list or set to sort, and M the number of returned elements. When the
  elements are not sorted, complexity is currently O(N) as there is a
  copy step that will be avoided in next release.

  More info: http://redis.io/commands/sort

  ## Return value

  Multi-bulk reply: list of sorted elements.

  """
  """
  It would be nice to have something like

    def sort(client // connect, key, opt1 // nil,
      opt2 // nil, opt3 // nil, opt4 // nil, opt5 // nil, opt6 // nil)

  For now let the options just be a list or a non-list value.
  """
  def sort(client // connect, key, options // nil)

  # For Redi.sort client, "key"
  #   or, Redi.sort "key"
  def sort(client, key, options) when is_pid(client) and nil?(options),
    do: query(client, [ "SORT", key ])

  # For Redi.sort client, "key", ["opt1", "opt2", "opt2v1", "opt2v2", "etc"]
  def sort(client, key, options) when is_pid(client) and is_list(options),
    do: query(client, [ "SORT" | [ key | options ] ])

  # For Redi.sort "key", ["opt1", "opt2", "opt2v1", "opt2v2", "etc"]
  def sort(key, options, _) when not is_pid(key) and is_list(options),
    do: connect |> query [ "SORT" | [ key | options ] ]

  # For Redi.sort "key", "non-list-option"
  def sort(key, option, _) when not is_pid(key),
    do: connect |> query [ "SORT", key, option ]

  # For Redi.sort client, "key", "non-list-option"
  def sort(client, key, option),
    do: query(client, [ "SORT", key, option ])

  @doc """
  ## QUIT

  Close the connection

  More info: http://redis.io/commands/quit

  ## Return value

  Status code reply. Always OK.

  """
  def quit(client // connect), do: query(client, [ "QUIT" ])

  @doc """
  ## UNSUBSCRIBE [channel [channel ...]]

  Stop listening for messages posted to the given channels

  Time complexity: O(N) where N is the number of clients already subscribed
  to a channel.

  More info: http://redis.io/commands/unsubscribe

  #FIXME

  """
  # For Redi.unsubscribe client
  def unsubscribe(client, channel) when is_pid(client) and nil?(channel) do
  end

  # For Redi.unsubscribe client, "channel"
  def unsubscribe() do
  end

  @doc """
  ## UNWATCH

  Forget about all watched keys

  Time complexity: O(1)

  More info: http://redis.io/commands/unwatch

  Status code reply. Always OK.

  """
  def unwatch(client // connect), do: query(client, [ "UNWATCH" ])

  @doc """
  ## WATCH key [key ...]

  Watch the given keys to determine execution of the MULTI/EXEC block

  Time complexity: O(1) for every key.

  More info: http://redis.io/commands/watch

  ## Return value

  Status code reply. Always OK.

  """
  def watch(client // connect, key) do
    if is_list(key) do
      query(client, [ "WATCH" | key ])
    else
      query(client, [ "WATCH", key ])
    end
  end

  @doc """
  ## ZADD key score member [score member ...]

  Add one or more members to a sorted set, or update its score if it
  already exists

  Time complexity: O(log(N)) where N is the number of elements in the
  sorted set.

  More info: http://redis.io/commands/zadd

  ## Return value

  Integer reply, specifically, the number of elements added to the sorted sets,
  not including elements already existing for which the score was updated.

  ## Examples

    iex> Redi.del "zazset"
    "0"
    iex> Redi.zadd "zazset", 1, "one"
    "1"
    iex> Redi.zadd "zazset", 1, "uno"
    "1"
    iex> Redi.zadd "zazset", 2, "two"
    "1"
    iex> Redi.zadd "zazset", 3, "two"
    "0"
    iex> Redi.zrange "zazset", 0, -1, "WITHSCORES"
    ["one", "1", "uno", "1", "two", "3"]
    iex> Redi.del "zazset"
    "1"

  """
  def zadd(client // connect, key, score, member // nil)

  # For Redi.zadd client, "key", ["s1", "m1", "s2", "m2", "sn", mn"]
  # Or, for Redi.zadd "key", ["s1", "m1", "s2", "m2", "sn", mn"]
  def zadd(client, key, score_member, opt2) when is_pid(client) and
           is_list(score_member) and nil?(opt2),

    do: query(client, [ "ZADD" | [ key | score_member ] ])

  # For Redi.zadd "key", "score", "member"
  def zadd(key, score, member, _) when not is_pid(key),
    do: connect |> query [ "ZADD", key, score, member ]

  # For Redi.zadd client, "key", "score", "member"
  def zadd(client, key, score, member),
    do: query(client, [ "ZADD", key, score, member ])

  @doc """
  ## ZCARD key

  Get the number of members in a sorted set

  More info: http://redis.io/commands/zcard

  ## Return value

  Integer reply. The cardinality (number of elements) of the sorted set,
  or 0 if key does not exist.

  ## Examples

    iex> Redi.del "zczset"
    "0"
    iex> Redi.zadd "zczset", 1, "one"
    "1"
    iex> Redi.zadd "zczset", 2, "two"
    "1"
    iex> Redi.zcard "zczset"
    "2"
    iex> Redi.del "zczset"
    "1"

  """
  def zcard(client // connect, key), do: query(client, [ "ZCARD", key ])

  @doc """
  ## ZCOUNT key min max

  Count the members in a sorted set with scores within the given values

  Time complexity: O(log(N)+M) with N being the number of elements in the
  sorted set and M being the number of elements between mix and max.

  More info: http://redis.io/commands/zcount

  ## Return value

  Integer reply. The number of elements in the specified score range.

  ## Examples

    iex> Redi.del "zcnzset"
    "0"
    iex> Redi.zadd "zcnzset", 1, "one"
    "1"
    iex> Redi.zadd "zcnzset", 2, "two"
    "1"
    iex> Redi.zadd "zcnzset", 3, "three"
    "1"
    iex> Redi.zcount "zcnzset", "-inf", "+inf"
    "3"
    iex> Redi.zcount "zcnzset", "(1", 3
    "2"
    iex> Redi.del "zcnzset"
    "1"

  """
  def zcount(client // connect, key, min, max),
    do: query(client, [ "ZCOUNT", key, min, max ])

  @doc """
  ## ZINCRBY key increment member

  Increment the score of a member in a sorted set

  Time complexity: O(log(N)) where N is the number of elements in the
  sorted set.

  More info: http://redis.io/commands/zincrby

  ## Return value

  Bulk reply: the new score of member (a double precision floating point
  number), represented as string.

  ## Example

    iex> Redi.del "zbyzset"
    "0"
    iex> Redi.zadd "zbyzset", 1, "one"
    "1"
    iex> Redi.zadd "zbyzset", 2, "two"
    "1"
    iex> Redi.zincrby "zbyzset", 2, "one"
    "3"
    iex> Redi.zrange "zbyzset", 0, -1, "WITHSCORES"
    ["two", "2", "one", "3"]
    iex> Redi.del "zbyzset"
    "1"

  """
  def zincrby(client // connect, key, increment, member),
    do: query(client, [ "ZINCRBY", key, increment, member ])

  @doc """
  ## ZINTERSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]]
  [AGGREGATE SUM|MIN|MAX]

  Intersect multiple sorted sets and store the resulting sorted set in a
  new key

  Time complexity: O(N)

  More info: http://redis.io/commands/zinterstore

  ## Return value

  Integer reply. The number of elements in the resulting sorted set at
  destination.

  ## Examples

        iex> db = Redi.connect
        iex> Redi.del db, ["out", "zntrszset1", "zntrszset2"]
        "0"
        iex> Redi.zadd db, "zntrszset1", 1, "one"
        "1"
        iex> Redi.zadd db, "zntrszset1", 2, "two"
        "1"
        iex> Redi.zadd db, "zntrszset2", 1, "one"
        "1"
        iex> Redi.zadd db, "zntrszset2", 2, "two"
        "1"
        iex> Redi.zadd db, "zntrszset2", 3, "three"
        "1"
        iex> Redi.zinterstore db, "out", 2, ["zntrszset1", "zntrszset2"], ["WEIGHTS", 2, 3]
        "2"
        iex> Redi.zrange db, "out", 0, -1, "WITHSCORES"
        ["one", "5", "two", "10"]
        iex> Redi.del db, ["out", "zntrszset1", "zntrszset2"]
        "3"
        iex> Redi.disconnect db
        :ok

  """
  def zinterstore(client // connect, dest, numkeys, key, opt1 // nil, opt2 // nil)

  # For three or four parameters passed (which means no opt1 or opt2)
  #
  # This will be called if three parameters were passed. This will also be
  # called if four parameters were passed and the first one is a client.
  #
  # e.g., Redi.zinterstore client, "dest", numkeys, "key"
  # or, Redi.zinterstore client, "dest", numkeys, ["key1", "key2", "keyn"]
  #
  def zinterstore(client, dest, numkeys, key, opt1, opt2) when nil?(opt1) and
                  nil?(opt2) and is_pid(client) do

    if is_list(key) do
      query(client, [ "ZINTERSTORE" | [ dest | [ numkeys | key ] ] ])
    else
      query(client, [ "ZINTERSTORE", dest, numkeys, key ])
    end

  end

  # For four parameters
  #
  # This will be called if four parameters were passed and the first one
  # is NOT a client.
  #
  # e.g., Redi.zinterstore "dest", numkeys, "key", ["opt", "value"]
  # or, Redi.zinterstore "dest", numkeys, ["k1", "k2", "kn"], ["opt", "value"]
  #
  # Note: "opt1" should be a list
  #
  def zinterstore(dest, numkeys, key, opt1, opt2, _) when not is_pid(dest) and
                  nil?(opt2) do

    if is_list(key) do
      connect |> query [
        "ZINTERSTORE" | [ dest | [ numkeys | key ++ opt1 ] ] ]
    else
      connect |> query [
        "ZINTERSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ] ] ]
    end

  end

  # For five parameters
  #
  # This will be called if five parameters were passed and the first one
  # is a client.
  #
  # e.g., Redi.zinterstore client, "dest", numkeys, "key", "opt1"
  # or, Redi.zinterstore client, "dest", numkeys, ["k1", "k2", "kn"], "opt1"
  #
  # Note: "opt1" should be a list
  #
  def zinterstore(client, dest, numkeys, key, opt1, opt2) when is_pid(client)
                  and nil?(opt2) do

    if is_list(key) do
      query(client,
        [ "ZINTERSTORE" | [ dest | [ numkeys | key ++ opt1 ] ] ])
    else
      query(client,
        [ "ZINTERSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ] ] ])
    end

  end

  # For five parameters
  #
  # This will be called if five parameters were passed and the first one
  # is NOT a client.
  #
  # e.g., Redi.zinterstore "dest", numkeys, "key", ["o1", "v1"], ["o2", "v2"]
  # or, Redi.zinterstore "dest", numkeys, ["k1", "k2", "kn"], ["o1", "v1"],
  #       ["o2", "v2"]
  #
  # Note: "opt1" and "opt2" should be lists
  #
  def zinterstore(dest, numkeys, key, opt1, opt2, _) when not is_pid(dest) do
    if is_list(key) do
      connect |> query [
        "ZINTERSTORE" | [ dest | [ numkeys | key ++ opt1 ++ opt2 ] ] ]
    else
      connect |> query [
        "ZINTERSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ++ opt2 ] ] ]
    end
  end

  # For six parameters
  #
  # This will be called if ALL parameters were passed and the first one
  # is a client.
  #
  # e.g., Redi.zinterstore client, "dest", numkeys, "key", ["o1", "v1"],
  #         ["o2", "v2"]
  # or, Redi.zinterstore client, "dest", numkeys, ["k1", "k2", "kn"],
  #         ["o1", "v1"], ["o2", "v2"]
  #
  # Note: "opt1" and "opt2" should be lists
  #
  def zinterstore(client, dest, numkeys, key, opt1, opt2) do
    if is_list(key) do
      query(client,
        [ "ZINTERSTORE" | [ dest | [ numkeys | key ++ opt1 ++ opt2 ] ] ])
    else
      query(client,
        [ "ZINTERSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ++ opt2 ] ] ])
    end
  end

  @doc """
  ## ZRANGE key start stop [WITHSCORES]

  Return a range of members in a sorted set, by index

  More info: http://redis.io/commands/zrange

  ## Return value

  ## Examples

    iex> Redi.del "zrnzset"
    "0"
    iex> Redi.zadd "zrnzset", 1, "one"
    "1"
    iex> Redi.zadd "zrnzset", 2, "two"
    "1"
    iex> Redi.zadd "zrnzset", 3, "three"
    "1"
    iex> Redi.zrange "zrnzset", 0, -1
    ["one", "two", "three"]
    iex> Redi.zrange "zrnzset", 2, 3
    ["three"]
    iex> Redi.zrange "zrnzset", -2, -1
    ["two", "three"]
    iex> Redi.del "zrnzset"
    "1"

  """
  def zrange(client // connect, key, range_start, range_stop, withscores // nil)

  # Three or four parameters passed (which means no WITHSCORES)
  #
  # This will be called if three parameters were passed. This will also be
  # called if four parameters were passed and the first one is a client.
  #
  # e.g., Redi.zrange "key", range_start, range_stop
  # or, Redi.zrange client, "key", range_start, range_stop
  #
  def zrange(client, key, range_start, range_stop, withscores) when
             is_pid(client) and nil?(withscores),

    do: query(client, [ "ZRANGE", key, range_start, range_stop ])

  # Four parameters passed (WITHSCORES no client)
  def zrange(key, range_start, range_stop, withscores, _) when not is_pid(key),
    do: connect |> query [ "ZRANGE", key, range_start, range_stop, withscores ]

  # All (five) parameters passed (WITHSCORES with client)
  def zrange(client, key, range_start, range_stop, withscores),
    do: query(client, [ "ZRANGE", key, range_start, range_stop, withscores ])

  @doc """
  ## ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]

  Return a range of members in a sorted set, by score

  Time complexity: O(log(N)+M) with N being the number of elements in the
  sorted set and M the number of elements being returned. if M is constant
  (e.g. always asking for the first 10 elements with LIMIT), you can consider
  it O(log(N)).

  More info: http://redis.io/commands/zrangebyscore

  ## Return value

  Multi-bulk reply. List of elements in the specified score range (optionally
  with their scores).

  ## Examples

    iex> Redi.del "zrcrzset"
    "0"
    iex> Redi.zadd "zrcrzset", 1, "one"
    "1"
    iex> Redi.zadd "zrcrzset", 2, "two"
    "1"
    iex> Redi.zadd "zrcrzset", 3, "three"
    "1"
    iex> Redi.zrangebyscore "zrcrzset", "-inf", "+inf"
    ["one", "two", "three"]
    iex> Redi.zrangebyscore "zrcrzset", 1, 2
    ["one", "two"]
    iex> Redi.zrangebyscore "zrcrzset", "(1", 2
    ["two"]
    iex> Redi.zrangebyscore "zrcrzset", "(1", "(2"
    []
    iex> Redi.del "zrcrzset"
    "1"

  """
  def zrangebyscore(client // connect, key, min, max, opt1 // nil, opt2 // nil)

  # Three or four parameters passed
  #
  # This will be called if three parameters were passed. This will also be
  # called if four parameters were passed and the first one is a client
  # (which means no WITHSCORES, no LIMIT).
  #
  # e.g., Redi.zrangebyscore "key", min, max
  # or, Redi.zrange client, "key", min, max
  #
  def zrangebyscore(client, key, min, max, opt1, opt2) when is_pid(client) and
                    nil?(opt1) and nil?(opt2),

    do: query(client, [ "ZRANGEBYSCORE", key, min, max ])

  # Five parameters passed
  def zrangebyscore(client, key, min, max, opt1, opt2) when is_pid(client) and
                    nil?(opt2) do

    if is_list(opt1) do
      query(client, [ "ZRANGEBYSCORE" | [ key | [ min | [ max | opt1 ] ] ] ])
    else
      query(client, [ "ZRANGEBYSCORE", key, min, max, opt1 ])
    end

  end

  # Four parameters passed; first is NOT a client
  def zrangebyscore(key, min, max, opt1, opt2, _) when not is_pid(key) and
                    nil?(opt2) do

    if is_list(opt1) do
      connect |> query [ "ZRANGEBYSCORE" | [ key | [ min | [ max | opt1 ] ] ] ]
    else
      connect |> query [ "ZRANGEBYSCORE", key, min, max, opt1 ]
    end

  end

  # Five parameters passed; first is NOT a client; only one opt should be a list
  def zrangebyscore(key, min, max, opt1, opt2, _) when not is_pid(key) do
    if is_list(opt1) do
      connect |> query [
        "ZRANGEBYSCORE" | [ key | [ min | [ max | opt1 ++ [ opt2 ] ] ] ] ]
    else
      connect |> query [
        "ZRANGEBYSCORE" | [ key | [ min | [ max | [ opt1 ] ++ opt2 ] ] ] ]
    end
  end

  # All parameters passed; first is a client; only one opt should be a list
  def zrangebyscore(client, key, min, max, opt1, opt2) do
    if is_list(opt1) do
      query(client,
        [ "ZRANGEBYSCORE" | [ key | [ min | [ max | opt1 ++ [ opt2 ] ] ] ] ])
    else
      query(client,
        [ "ZRANGEBYSCORE" | [ key | [ min | [ max | [ opt1 ] ++ opt2 ] ] ] ])
    end
  end

  @doc """
  ## ZRANK key member

  Determine the index of a member in a sorted set

  Time complexity: O(log(N))

  More info: http://redis.io/commands/zrank

  ## Return value

  * If member exists in the sorted set, integer reply: The rank of member.
  * If member does not exist in the sorted set or key does not exist, Bulk
  reply: nil.

  ## Examples

    iex> Redi.del "zrnkzset"
    "0"
    iex> Redi.zadd "zrnkzset", 1, "one"
    "1"
    iex> Redi.zadd "zrnkzset", 2, "two"
    "1"
    iex> Redi.zadd "zrnkzset", 3, "three"
    "1"
    iex> Redi.zrank "zrnkzset", "three"
    "2"
    iex> Redi.zrank "zrnkzset", "four"
    :undefined
    iex> Redi.del "zrnkzset"
    "1"

  """
  def zrank(client // connect, key, member),
    do: query(client, [ "ZRANK", key, member ])

  @doc """
  ## ZREM key member [member ...]

  Remove one or more members from a sorted set

  More info: http://redis.io/commands/zrem

  ## Return value

  Integer reply, specifically:

  The number of members removed from the sorted set, not including
  non-existing members.

  ## Examples

    iex> Redi.del "zrmzset"
    "0"
    iex> Redi.zadd "zrmzset", 1, "one"
    "1"
    iex> Redi.zadd "zrmzset", 2, "two"
    "1"
    iex> Redi.zadd "zrmzset", 3, "three"
    "1"
    iex> Redi.zrem "zrmzset", "two"
    "1"
    iex> Redi.zrange "zrmzset", 0, -1, "WITHSCORES"
    ["one", "1", "three", "3"]
    iex> Redi.del "zrmzset"
    "1"

  """
  def zrem(client // connect, key, member) do
    if is_list(member) do
      query(client, [ "ZREM" | [ key | member ] ])
    else
      query(client, [ "ZREM", key, member ])
    end
  end

  @doc """
  ## ZREMRANGEBYRANK key start stop

  Remove all members in a sorted set within the given indexes

  More info: http://redis.io/commands/zremrangebyrank

  ## Return value

  Integer reply. The number of elements remove.

  ## Examples

    iex> Redi.del "zbrnzset"
    "0"
    iex> Redi.zadd "zbrnzset", 1, "one"
    "1"
    iex> Redi.zadd "zbrnzset", 2, "two"
    "1"
    iex> Redi.zadd "zbrnzset", 3, "three"
    "1"
    iex> Redi.zremrangebyrank "zbrnzset", 0, 1
    "2"
    iex> Redi.zrange "zbrnzset", 0, -1, "WITHSCORES"
    ["three", "3"]
    iex> Redi.del "zbrnzset"
    "1"

  """
  def zremrangebyrank(client // connect, key, range_start, range_stop),
    do: query(client, [ "ZREMRANGEBYRANK", key, range_start, range_stop ])

  @doc """
  ## ZREMRANGEBYSCORE key min max

  Remove all members in a sorted set within the given scores

  Time complexity: O(log(N)+M) with N being the number of elements in the
  sorted set and M the number of elements removed by the operation.

  More info: http://redis.io/commands/zremrangebyscore

  ## Return value

  Integer reply. The number of elements removed.

  ## Examples

    iex> Redi.del "zrmbzset"
    "0"
    iex> Redi.zadd "zrmbzset", 1, "one"
    "1"
    iex> Redi.zadd "zrmbzset", 2, "two"
    "1"
    iex> Redi.zadd "zrmbzset", 3, "three"
    "1"
    iex> Redi.zremrangebyscore "zrmbzset", "-inf", "(2"
    "1"
    iex> Redi.zrange "zrmbzset", 0, -1, "WITHSCORES"
    ["two", "2", "three", "3"]
    iex> Redi.del "zrmbzset"
    "1"

  """
  def zremrangebyscore(client // connect, key, min, max),
    do: query(client, [ "ZREMRANGEBYSCORE", key, min, max ])

  @doc """
  ## ZREVRANGE key start stop [WITHSCORES]

  Return a range of members in a sorted set, by index, with scores ordered
  from high to low

  Time complexity: O(log(N)+M) with N being the number of elements in the
  sorted set and M the number of elements returned.

  More info: http://redis.io/commands/zrevrange

  ## Return value

  Multi-bulk reply. List of elements in the specified range (optionally
  with their scores).

  ## Examples

    iex> Redi.del "zrvrzset"
    "0"
    iex> Redi.zadd "zrvrzset", 1, "one"
    "1"
    iex> Redi.zadd "zrvrzset", 2, "two"
    "1"
    iex> Redi.zadd "zrvrzset", 3, "three"
    "1"
    iex> Redi.zrevrange "zrvrzset", 0, -1
    ["three", "two", "one"]
    iex> Redi.zrevrange "zrvrzset", 2, 3
    ["one"]
    iex> Redi.zrevrange "zrvrzset", -2, -1
    ["two", "one"]
    iex> Redi.del "zrvrzset"
    "1"

  """
  def zrevrange(client // connect, key, range_start, range_stop, withscores // nil)

  # Three or four parameters passed; If four, first is a client
  #
  # e.g., Redi.zrevrange "key", range_start, range_stop
  # or, Redi.zrevrange client, "key", range_start, range_stop
  #
  def zrevrange(client, key, range_start, range_stop, withscores) when
                is_pid(client) and nil?(withscores),

    do: query(client, [ "ZREVRANGE", key, range_start, range_stop ])

  # Four parameters passed; first is NOT a client
  #
  # For Redi.zrevrange "key", range_start, range_stop, "WITHSCORES"
  #
  def zrevrange(key, range_start, range_stop, withscores, _) when not
                is_pid(key),
    do: connect |> query [
          "ZREVRANGE", key, range_start, range_stop, withscores ]

  # All (five) parameters passed
  #
  # For Redi.zrevrange client, "key", range_start, range_stop, "WITHSCORES"
  #
  def zrevrange(client, key, range_start, range_stop, withscores),
    do: query(client, [ "ZREVRANGE", key, range_start, range_stop, withscores ])

  @doc """
  ## ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]

  Return a range of members in a sorted set, by score, with scores ordered
  from high to low

  Time complexity: O(log(N)+M) with N being the number of elements in the
  sorted set and M the number of elements returned. if M is constant (e.g.
  always asking for the first 10 elements with LIMIT), you can consider it
  O(log(N)).

  More info: http://redis.io/commands/zrevrangebyscore

  ## Return value

  Multi-bulk reply. List of elements in the specified score range (optionally
  with their scores).

  ## Examples

    iex> Redi.del "zrvbszset"
    "0"
    iex> Redi.zadd "zrvbszset", 1, "one"
    "1"
    iex> Redi.zadd "zrvbszset", 2, "two"
    "1"
    iex> Redi.zadd "zrvbszset", 3, "three"
    "1"
    iex> Redi.zrevrangebyscore "zrvbszset", "+inf", "-inf"
    ["three", "two", "one"]
    iex> Redi.zrevrangebyscore "zrvbszset", 2, 1
    ["two", "one"]
    iex> Redi.zrevrangebyscore "zrvbszset", 2, "(1"
    ["two"]
    iex> Redi.zrevrangebyscore "zrvbszset", "(2", "(1"
    []
    iex> Redi.del "zrvbszset"
    "1"

  """
  def zrevrangebyscore(client // connect, key, min, max, opt1 // nil, opt2 // nil)

  def zrevrangebyscore(client, key, min, max, opt1, opt2) when nil?(opt1) and
                       nil?(opt2) and is_pid(client),

    do: query(client, [ "ZREVRANGEBYSCORE", key, min, max ])

  def zrevrangebyscore(client, key, min, max, opt1, opt2) when nil?(opt2) and
                       is_pid(client) do

    if is_list(opt1) do
      query(client, [ "ZREVRANGEBYSCORE" | [ key | [ min | [ max | opt1 ] ] ] ])
    else
      query(client, [ "ZREVRANGEBYSCORE", key, min, max, opt1 ])
    end

  end

  def zrevrangebyscore(key, min, max, opt1, opt2, _) when nil?(opt1) and
                       nil?(opt2) and not is_pid(key),
    do: connect |> query [ "ZREVRANGEBYSCORE", key, min, max ]

  def zrevrangebyscore(key, min, max, opt1, opt2, _) when nil?(opt2) and not
                       is_pid(key) do

    if is_list(opt1) do
      connect |> query [ "ZREVRANGEBYSCORE" | [ key | [ min | [ max | opt1 ] ] ] ]
    else
      connect |> query [ "ZREVRANGEBYSCORE", key, min, max, opt1 ]
    end

  end

  def zrevrangebyscore(key, min, max, opt1, opt2, _) when not is_pid(key) do
    if is_list(opt1) do
      connect |> query [
        "ZREVRANGEBYSCORE" | [ key | [ min | [ max | opt1 ++ [ opt2 ] ] ] ] ]
    else
      connect |> query [
        "ZREVRANGEBYSCORE" | [ key | [ min | [ max | [ opt1 ] ++ opt2 ] ] ] ]
    end
  end

  def zrevrangebyscore(client, key, min, max, opt1, opt2) do
    if is_list(opt1) do
      query(client,
        [ "ZREVRANGEBYSCORE" | [ key | [ min | [ max | opt1 ++ [ opt2 ] ] ] ] ])
    else
      query(client,
        [ "ZREVRANGEBYSCORE" | [ key | [ min | [ max | [ opt1 ] ++ opt2 ] ] ] ])
    end
  end

  @doc """
  ## ZREVRANK key member

  Determine the index of a member in a sorted set, with scores ordered
  from high to low

  Time complexity: O(log(N))

  More info: http://redis.io/commands/zrevrank

  ## Return value

  * If member exists in the sorted set, Integer reply: the rank of mameber.
  * If member does not exist in the sorted set or key does not exist, Bulk
  reply: nil.

  ## Examples

    iex> Redi.del "zrvnkzset"
    "0"
    iex> Redi.zadd "zrvnkzset", 1, "one"
    "1"
    iex> Redi.zadd "zrvnkzset", 2, "two"
    "1"
    iex> Redi.zadd "zrvnkzset", 3, "three"
    "1"
    iex> Redi.zrevrank "zrvnkzset", "one"
    "2"
    iex> Redi.zrevrank "zrvnkzset", "four"
    :undefined
    iex> Redi.del "zrvnkzset"
    "1"

  """
  def zrevrank(client // connect, key, member),
    do: query(client, [ "ZREVRANK", key, member ])

  @doc """
  ## ZSCORE key member

  Get the score associated with the given member in a sorted set

  Time complexity: O(1)

  More info: http://redis.io/commands/zscore

  ## Return value

  Bulk reply: the score of member (a double precision floating point number),
  represented as string.

  ## Example

    iex> Redi.del "zscrzset"
    "0"
    iex> Redi.zadd "zscrzset", 1, "one"
    "1"
    iex> Redi.zscore "zscrzset", "one"
    "1"
    iex> Redi.del "zscrzset"
    "1"

  """
  def zscore(client // connect, key, member),
    do: query(client, [ "ZSCORE", key, member ])

  @doc """
  ## ZUNIONSTORE destination numkeys key [key ...] [WEIGHTS weigh [weight ...]]
  [AGGREGATE SUM|MIX|MAX]

  Add multiple sorted sets and store the resulting sorted set in a new key

  Time complexity: O(N)+O(M log(M)) with N being the sum of the sizes of
  the input sorted sets and M being the number of elements in the resulting
  sorted set.

  More info: http://redis.io/commands/zunionstore

  ## Return value

  Integer reply. The number of elements in the resulting sorted set at
  destination.

  ## Examples

    iex> Redi.del ["zset1", "zset2"]
    "0"
    iex> Redi.zadd "zset1", 1, "one"
    "1"
    iex> Redi.zadd "zset1", 2, "two"
    "1"
    iex> Redi.zadd "zset2", 1, "one"
    "1"
    iex> Redi.zadd "zset2", 2, "two"
    "1"
    iex> Redi.zadd "zset2", 3, "three"
    "1"
    iex> Redi.zunionstore "out", 2, ["zset1", "zset2"], ["WEIGHTS", 2, 3]
    "3"
    iex> Redi.zrange "out", 0, -1, "WITHSCORES"
    ["one", "5", "three", "9", "two", "10"]
    iex> Redi.del ["zset1", "zset2"]
    "2"

  """
  def zunionstore(client // connect, dest, numkeys, key, opt1 // nil, opt2 // nil)

  def zunionstore(client, dest, numkeys, key, opt1, opt2) when nil?(opt1) and
                  nil?(opt2) and is_pid(client) do

    if is_list(key) do
      query(client, [ "ZUNIONSTORE" | [ dest | [ numkeys | key ] ] ])
    else
      query(client, [ "ZUNIONSTORE", dest, numkeys, key ])
    end

  end

  def zunionstore(client, dest, numkeys, key, opt1, opt2) when nil?(opt2) and
                  is_pid(client) do

    if is_list(key) do
      query(client, [
         "ZUNIONSTORE" | [ dest | [ numkeys | key ++ opt1 ] ] ])
    else
      query(client, [
        "ZUNIONSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ] ] ])
    end

  end

  def zunionstore(dest, numkeys, key, opt1, opt2, _) when nil?(opt1) and
                  nil?(opt2) and not is_pid(dest) do

    if is_list(key) do
      connect |> query [ "ZUNIONSTORE" | [ dest | [ numkeys | key ] ] ]
    else
      connect |> query [ "ZUNIONSTORE", dest, numkeys, key ]
    end

  end

  def zunionstore(dest, numkeys, key, opt1, opt2, _) when nil?(opt2) and
                  not is_pid(dest) do

    if is_list(key) do
      connect |> query [
        "ZUNIONSTORE" | [ dest | [ numkeys | key ++ opt1 ] ] ]
    else
      connect |> query [
        "ZUNIONSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ] ] ]
    end

  end

  def zunionstore(client, dest, numkeys, key, opt1, opt2) do
    if is_list(key) do
      query(client,
        [ "ZUNIONSTORE" | [ dest | [ numkeys | key ++ opt1 ++ opt2 ] ] ])
    else
      query(client,
        [ "ZUNIONSTORE" | [ dest | [ numkeys | [ key ] ++ opt1 ++ opt2 ] ] ])
    end
  end

  #
  # Happy hacking!
  # -------------------------------------------------------------------- ed.o --

end
