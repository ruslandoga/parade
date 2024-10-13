defmodule Parade do
  @moduledoc """
  Helpers for building Ecto queries for ParadeDB.
  """

  @doc """
  Builds a ParadeDB search query that can be used in `Ecto.Query.from`

      from s in Parade.search("calls_search_idx", "transcript:walking")

  """
  def search(index, query)

  def search(index, query) when is_binary(query) do
    %Ecto.Query{
      from: %Ecto.Query.FromExpr{
        source:
          {:fragment, [],
           [
             {:raw, ""},
             {:expr, {:literal, [], [index]}},
             {:raw, ".search("},
             {:expr, {:^, [], [0]}},
             {:raw, ")"}
           ]},
        params: [{query, :any}]
      }
    }
  end

  def search(index, query) when is_list(query) do
    {insides, params} =
      build_insides(query, _acc = [], _idx = 0, _params = [])

    search =
      [
        raw: "",
        expr: {:literal, [], [index]},
        raw: ".search(query => paradedb.boolean(must => ARRAY["
      ] ++
        insides ++
        [raw: "]))"]

    search = merge_fragments(search)

    %Ecto.Query{
      from: %Ecto.Query.FromExpr{
        source: {:fragment, [], search},
        params: params
      }
    }
  end

  defp build_insides([op | rest], acc, idx, params) do
    case op do
      {:parse, value} when is_binary(value) ->
        q = [{:raw, "paradedb.parse("}, {:expr, {:^, [], [idx]}}, {:raw, ")"}]
        build_insides(rest, [q | acc], idx + 1, [{value, :any} | params])

      {:range, %{field: field, range: range}} when is_binary(field) and is_binary(range) ->
        q = [
          {:raw, "paradedb.range(field => "},
          {:expr, {:^, [], [idx]}},
          {:raw, ", range => "},
          {:expr, {:^, [], [idx + 1]}},
          {:raw, "::int4range)"}
        ]

        build_insides(rest, [q | acc], idx + 2, [{range, :any}, {field, :any} | params])
    end
  end

  defp build_insides([], acc, _idx, params) do
    {
      acc
      |> :lists.reverse()
      |> Enum.intersperse({:raw, ","})
      |> :lists.flatten(),
      :lists.reverse(params)
    }
  end

  defp merge_fragments([{:raw, raw1}, {:raw, raw2} | rest]) do
    merge_fragments([{:raw, raw1 <> raw2} | rest])
  end

  defp merge_fragments([{:raw, _raw} = raw, {:expr, _expr} = expr | rest]) do
    [raw, expr | merge_fragments(rest)]
  end

  defp merge_fragments([{:raw, _raw}] = done), do: done
end
