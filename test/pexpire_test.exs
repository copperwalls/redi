Code.require_file "test_helper.exs", __DIR__

defmodule PexpireTest do

  use ExUnit.Case, async: true

  import Redi

  test "with client set" do
    db1 = Redi.connect
    assert del(db1, "pxkey") <= "1"
    assert set(db1, "pxkey", "Hello") == "OK"
    assert pexpire(db1, "pxkey", 1000) == "1"
    assert ttl(db1, "pxkey") == "1"
    assert pttl(db1, "pxkey") <= "1000"
    assert del(db1, "pxkey") == "1"
    Redi.disconnect db1
  end

end
