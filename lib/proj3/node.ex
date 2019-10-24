defmodule Node do
  use GenServer

  def start_link(type,node_name,base_nodes,opts) do
    GenServer.start_link(__MODULE__, [type,node_name,base_nodes],opts)
  end

  def gettable(server) do
    GenServer.call(server,{:get_table})
  end

  def update_parent(_server,self_id,parent) do
    parent_pid = Master.lookup(MyMaster,parent)
    GenServer.cast(parent_pid,{:update_child,self_id})
  end

  def handle_call({:get_table},_from,state) do
    {:reply, state[:table], state}
  end

  def handle_cast({:update_child,child_id},state) do
    map = state[:table]
    self_id = state[:id]
    index0 = charmatch(child_id, self_id)
    index1 = String.at(child_id,index0)

    sibling_list = Enum.reduce(map[Integer.to_string(index0)], [], fn {_k, v}, list ->
      list ++ [v]
    end)
    sibling_list = Enum.filter(sibling_list,fn x-> x != "" end)

    map = put_in(map,[Integer.to_string(index0),index1],child_id)
    state = Map.put(state, :table, map)
    Enum.each sibling_list, fn sibling ->
      sibling_pid = Master.lookup(MyMaster,sibling)
      GenServer.cast(sibling_pid,{:update_sibling,child_id})
    end
    {:noreply,state}
  end

  def handle_cast({:update_sibling,sibling_id},state) do
    map = state[:table]
    self_id = state[:id]
    index0 = charmatch(sibling_id,self_id)
    index1 = String.at(sibling_id,index0)
    map = put_in(map,[Integer.to_string(index0),index1],sibling_id)
    state = Map.put(state, :table, map)
    {:noreply,state}
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
      parent = base_nodes
      map = Node.gettable(Master.lookup(MyMaster,parent))
      index1 = charmatch(self_id, parent)
      index2 = String.at(parent,index1)
      #IO.puts(map)
      map = put_in(map,[Integer.to_string(index1),index2],parent)
      #IO.puts map[Integer.to_string(index1)][index2]
      {:ok,
        %{
          :parent => parent,
          :table => map,
          :id => self_id
        }
      }
    end
  end

  def charmatch(child, parent) do
    char1 = String.at(parent, 0)
    char2 = String.at(parent, 1)
    char3 = String.at(parent, 2)

    if String.at(child, 0) == char1 && String.at(child, 1) == char2 &&
         String.at(child, 2) == char3 do
      3
    else
      if String.at(child, 0) == char1 && String.at(child, 1) == char2 do
        2
      else
        if String.at(child, 0) == char1 do
          1
        else
          0
        end
      end
    end
  end
end
