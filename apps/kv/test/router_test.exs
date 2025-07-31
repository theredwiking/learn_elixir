defmodule KV.RouterTest do
  use ExUnit.Case, async: true

  @tag :distributed
  test "route request to nodes" do
    assert KV.Router.route("hello", Kernel, :node, []) == :"foo@middleearth"
    assert KV.Router.route("world", Kernel, :node, []) == :"bar@middleearth"
  end

  test "raises on unknow entries" do
    assert_raise RuntimeError, ~r/could not find entry/, fn ->
      KV.Router.route(<<0>>, Kernel, :node, [])
    end
  end
end
