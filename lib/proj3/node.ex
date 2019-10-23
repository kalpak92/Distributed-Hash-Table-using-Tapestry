defmodule Node do
  use GenServer

  def start_link(type,node_name,base_nodes,opts) do
    GenServer.start_link(__MODULE__, [type,node_name,base_nodes],opts)
  end

  def gettable(server) do
    GenServer.call(server,{:get_table})
  end

  def handle_call({:get_table},_from,state) do
    {:reply, state[:table], state}
  end

  def init(args) do
    [type,self_id,base_nodes] = args
    Master.put(MyMaster,self_id,self())
    if type == "Base" do
      map0 = Enum.reduce(base_nodes--[self_id], %{}, fn x, acc->
        Map.put(acc,String.at(x,0),x)
      end)
      map1 = Enum.reduce(base_nodes, %{}, fn x, acc-> Map.put(acc,String.at(x,0),"") end)
      map2 = Enum.reduce(base_nodes, %{}, fn x, acc-> Map.put(acc,String.at(x,0),"") end)
      map3 = Enum.reduce(base_nodes, %{}, fn x, acc-> Map.put(acc,String.at(x,0),"") end)
      routing_table = %{
        "0" => map0,
        "1" => map1,
        "2" => map2,
        "3" => map3
      }
      {:ok,
        %{
          :parent => nil,
          :table => routing_table,
          :id => self_id
        }
      }
    else
      {:ok,
        %{
          :parent => base_nodes,
          :table => %{},
          :id => self_id
        }
      }
    end
  end

end
