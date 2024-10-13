defmodule ParadeTest do
  use ExUnit.Case
  doctest Parade

  test "greets the world" do
    assert Parade.hello() == :world
  end
end
