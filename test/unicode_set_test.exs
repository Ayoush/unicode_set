defmodule UnicodeSetTest do
  use ExUnit.Case
  alias Unicode.Set.Operation
  doctest Operation

  test "set intersection when one list is a true subset of another" do
    l = Unicode.Category.get(:L)
    ll = Unicode.Category.get(:Ll)
    assert Operation.intersect(l, ll) == ll
  end

  test "set intersection when the two lists are disjoint" do
    assert Operation.intersect([{1, 1}, {2, 2}, {3, 3}], [{4, 4}, {5, 5}, {6, 6}]) == []
    assert Operation.intersect([{4, 4}, {5, 5}, {6, 6}], [{1, 1}, {2, 2}, {3, 3}]) == []
  end

  test "set union" do
    assert Operation.union([2, 3, 4], [1, 2, 3]) == [1, 2, 3, 4]
    assert Operation.union([1, 2, 3], [2, 3, 4]) == [1, 2, 3, 4]
    assert Operation.union([1, 2, 3], [4, 5, 6]) == [1, 2, 3, 4, 5, 6]
  end

  test "set difference" do
    assert Operation.difference([{1, 1}, {2, 2}, {3, 3}], [{1, 1}, {2, 2}, {3, 3}]) == []
    assert Operation.difference([{1, 1}, {2, 2}, {3, 3}], [{1, 1}]) == [{2, 2}, {3, 3}]
    assert Operation.difference([{1, 1}, {2, 2}, {3, 3}], [{2, 3}]) == [{1, 1}]

    assert Operation.difference([{1, 3}, {4, 10}, {20, 40}], [{5, 9}]) == [
             {1, 3},
             {4, 4},
             {10, 10},
             {20, 40}
           ]
  end

  test "a guard module with match?/2" do
    defmodule Guards do
      require Unicode.Set

      # Define a guard that checks if a codepoint is a unicode digit
      defguard digit?(x) when Unicode.Set.match?(x, "[[:Nd:]]")
    end

    defmodule MyModule do
      require Unicode.Set
      require Guards

      # Define a function using the previously defined guard
      def my_function(<< x :: utf8, _rest :: binary>>) when Guards.digit?(x) do
        :digit
      end

      # Define a guard directly on the function
      def my_other_function(<< x :: utf8, _rest :: binary>>)
          when Unicode.Set.match?(x, "[[:Nd:]]") do
        :digit
      end
    end

    assert MyModule.my_function("3") == :digit
    assert MyModule.my_other_function("3") == :digit
  end

  test "set intersection matching" do
    require Unicode.Set

    assert Unicode.Set.match?(?๓, "[[:digit:]-[:thai:]]") == false
    assert Unicode.Set.match?(?๓, "[[:digit:]]") == true
  end

  test "prewalk/3" do
    {:ok, parsed, "", _, _, _} = Unicode.Set.parse("[abc]")
    fun = fn a, b, c -> {a, b, c} end

    result =
      parsed
      |> Unicode.Set.Operation.expand
      |> Unicode.Set.Operation.prewalk(fun)

    assert result == {{97, 97}, {{98, 98}, {{99, 99}, {[], [], nil}, nil}, nil}, nil}
  end

  test "compile_pattern/1" do
    require Unicode.Set

    pattern = Unicode.Set.compile_pattern "[[:digit:]]"
    list = String.split("abc1def2ghi3jkl", pattern)
    assert list == ["abc", "def", "ghi", "jkl"]
  end

  test "utf8_char/1" do
    assert Unicode.Set.utf8_char("[[^abcd][mnb]]") ==
      [{:not, 97}, {:not, 98}, {:not, 99}, {:not, 100}, 98, 109, 110]
  end
end
