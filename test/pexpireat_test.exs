Code.require_file "test_helper.exs", __DIR__

defmodule PexpireatTest do

  use ExUnit.Case, async: true

  import Redi

  test "with client set" do
    db1 = Redi.connect
    assert del(db1, "pxakey") <= "1"
    assert set(db1, "pxakey", "Hello") == "OK"
    assert pexpireat(db1, "pxakey", 1555555555005) == "1"
    assert ttl(db1, "pxakey") <= "178890087"
    assert pttl(db1, "pxakey") <= "178890008317"
    assert del(db1, "pxakey") == "1"
    Redi.disconnect db1
  end

end
