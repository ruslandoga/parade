defmodule ParadeTest do
  use ExUnit.Case
  import Ecto.Query

  defp all(query) do
    {query, _cast_params, _dump_params} =
      Ecto.Adapter.Queryable.plan_query(:all, Ecto.Adapters.Postgres, query)

    query
    |> Ecto.Adapters.Postgres.Connection.all()
    |> IO.iodata_to_binary()
  end

  # queries from https://github.com/Moosieus/paradedb-elixir-api-proposal#the-from-expression
  test "it sqls" do
    assert all(
             from(s in Parade.search("calls_search_idx", "transcript:walking"),
               where: fragment("call_length") > 3,
               select: s.id
             )
           ) ==
             """
             SELECT f0."id" \
             FROM "calls_search_idx".search($1) AS f0 \
             WHERE (call_length > 3)\
             """

    assert all(
             from(
               s in Parade.search("calls_search_idx",
                 parse: "transcript:walking",
                 range: %{field: "call_length", range: "[3,)"}
               ),
               join: t in "talk_groups",
               on: t.id == s.talk_group_id,
               select: s.id
             )
           ) ==
             """
             SELECT f0."id" \
             FROM "calls_search_idx".search(query => \
             paradedb.boolean(must => ARRAY[\
             paradedb.parse($1),\
             paradedb.range(field => $2, range => $3::int4range)\
             ])) AS f0 \
             INNER JOIN "talk_groups" AS t1 \
             ON t1."id" = f0."talk_group_id"\
             """
  end
end
