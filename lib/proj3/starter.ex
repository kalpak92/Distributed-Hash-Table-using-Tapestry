defmodule Starter do
  def start(args) do
    [numNodes, numReq] = args

    {numNodes, _} = Integer.parse(numNodes)
    {numReq, _} = Integer.parse(numReq)

    # ets table
    # data = :ets.new(:data, [:set, :named_table, :public])

    # starting the Master GenServer
    {:ok, master_pid} = Master.start_link([])
    Process.register master_pid, MyMaster
    IO.puts("In Starter")
    base_nodes = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "0000", "A124", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF"]

    Enum.each(base_nodes, fn(i)->
      node_name = i |> String.to_atom()
      #IO.inspect(node_name)

      {:ok, _node_pid} = Node.start_link("first", node_name, base_nodes,[])

      #Node.gettable(node_pid);
    end)

    node_list = Master.get(MyMaster)

    Enum.each(0..15, fn(i) ->
    any_node = Enum.fetch!(node_list,i)

    node_pid = Master.lookup(MyMaster,any_node)


    IO.puts any_node
    IO.inspect node_pid

    end)

    map = Node.gettable(Master.lookup(MyMaster,Enum.fetch!(node_list,4)))
    Enum.each 0..3, fn(i) ->
      IO.puts(i);
      Enum.each map[Integer.to_string(i)], fn {k, v} ->
        IO.puts "#{k} --> #{v}"
      end
    end

    #IO.puts map["0"]["A"]

  end

end
