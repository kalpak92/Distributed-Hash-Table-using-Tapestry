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

    base_nodes = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "0000", "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF"]

    Enum.each(base_nodes, fn(i)->
      node_name = i |> String.to_atom()
      # {:ok, node_pid} = Peer.start_link(20, data, node_name,[])
      {:ok, _node_pid} = Node.start_link("first", node_name, [])
    end)
    node_list = Chief.get(MyMaster)

  end
end
