defmodule Node do
  use GenServer

  def start_link(type,node_name,base_nodes,opts) do
    GenServer.start_link(__MODULE__, [type,node_name,base_nodes],opts)
  end

  def gettable(server) do
    GenServer.call(server,{:get_table})
  end

  def lookup(server,destination_node) do
    GenServer.cast(server,{:find_destination,destination_node,0})
  end

  def update_parent(_server,self_id,parent) do
    parent_pid = Master.lookup(MyMaster,parent)
    GenServer.cast(parent_pid,{:update_child,self_id})
  end

  def handle_call({:get_table},_from,state) do
    {:reply, state[:table], state}
  end

  def handle_cast({:find_destination,destination_id,hop},state) do
    map = state[:table]
    self_id = state[:id]
    index0 = charmatch(self_id,destination_id)
    index1 = String.at(destination_id,index0)

    if map[Integer.to_string(index0)][index1] == destination_id do
      Stage.savemax(MyStage,hop)
    else
      hop_pid = Master.lookup(MyMaster,map[Integer.to_string(index0)][index1])
      GenServer.cast(hop_pid,{:find_destination,destination_id,hop+1})
    end
    {:noreply,state}
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
      GenServer.cast(sibling_pid,{:update_sibling,child_id,index0+1})
    end
    if index0<3 do
      GenServer.cast(self(),{:update_children,child_id,index0+1})
    end
    {:noreply,state}
  end

  def handle_cast({:update_children,child_id,start_level},state) do
    map = state[:table]

    Enum.each start_level..3, fn x ->
      siblingsatsamelevel = Enum.reduce(map[Integer.to_string(x)], [], fn {_k,v}, list ->
        list ++ [v]
      end)
      siblingsatsamelevel = Enum.filter(siblingsatsamelevel,fn x-> x != "" end)
      Enum.each siblingsatsamelevel, fn sibling ->
        sibling_pid = Master.lookup(MyMaster, sibling)
        GenServer.cast(sibling_pid,{:update_sibling,child_id,x+1})
      end
    end
    {:noreply,state}
  end

  def handle_cast({:update_sibling,update_id,start_level},state) do
    map = state[:table]
    self_id = state[:id]
    index0 = charmatch(update_id,self_id)
    index1 = String.at(update_id,index0)
    if start_level <= 3 do
      Enum.each start_level..3, fn x ->
        siblingsatsamelevel = Enum.reduce(map[Integer.to_string(x)], [], fn {_k,v}, list ->
          list ++ [v]
        end)
        siblingsatsamelevel = Enum.filter(siblingsatsamelevel,fn x-> x != "" end)
        Enum.each siblingsatsamelevel, fn sibling ->
          sibling_pid = Master.lookup(MyMaster, sibling)
          GenServer.cast(sibling_pid,{:update_sibling,update_id,x+1})
        end
      end
    end
    map = put_in(map,[Integer.to_string(index0),index1],update_id)
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

      list = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
      mapnull = Enum.reduce(list, %{}, fn x, acc-> Map.put(acc,x,"") end)

      map = Enum.reduce index1+1..3, map, fn (i), map ->
        indexstr = Integer.to_string(i)
        Map.put(map,indexstr,mapnull)
      end

      map = put_in(map,[Integer.to_string(index1),index2],parent)

      {:ok,
        %{
          :parent => parent,
          :table => map,
          :id => self_id
        }
      }
    end
  end

  @doc """
  Get the number of characters that matches.
  """
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
