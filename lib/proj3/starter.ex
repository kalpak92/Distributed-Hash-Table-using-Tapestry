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

    {:ok, stage_pid} = Stage.start_link([])
    Process.register stage_pid, MyStage

    IO.puts("In Starter")
    base_nodes = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "0000", "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF"]
    numNodes = numNodes - 16
    Enum.each(base_nodes, fn(i)->
      {:ok, _node_pid} = Node.start_link("Base", i, base_nodes,[])
    end)

    #test_list = ["AABA","AACD","A123","A928","A931","A948","A921","A959","A951","A341","A352"]

    #testing for routing table

    #Enum.each(test_list, fn(i)->
     # {parent, _count} = leading_match(i)
     # IO.puts("#{i} parent is #{parent}")
     # {:ok,node_pid} = Node.start_link("Dynamic",i, parent,[])
     # Node.update_parent(node_pid,i,parent)
    #end)


   Enum.each(1..numNodes, fn(i) ->
      node_name = Integer.to_string(i) |> hash_modulus()
      #node_list = Master.get(MyMaster)
      {parent, _count} = leading_match(node_name)
      #IO.puts("#{node_name} parent is #{parent}")
      {:ok,node_pid} = Node.start_link("Dynamic", node_name,parent,[])
      Node.update_parent(node_pid,node_name,parent)
    end)

    :timer.sleep(1000)

    node_list = Master.get(MyMaster)

    #any_node = Enum.at(node_list,:rand.uniform(length(node_list)))
    #IO.puts ("Node we are inspecting: #{any_node}")
    #node_pid = Master.lookup(MyMaster,any_node)
    #map_of_rand_node = Node.gettable(node_pid)

    #Enum.each 0..3, fn(i) ->
    #  IO.puts "Level #{i}"
    #  Enum.each map_of_rand_node[Integer.to_string(i)], fn {k,v} ->
    #    IO.puts "#{k} --> #{v}"
    #  end
    #end

    source_node = Enum.at(node_list,:rand.uniform(length(node_list)))
    destination_list = node_list--[source_node]

    destination_node = Enum.at(destination_list,:rand.uniform(length(destination_list)))
    #source_node = "1111"
    #destination_node = "365C"
    IO.puts "#{source_node} trying to reach #{destination_node}"
    source_pid = Master.lookup(MyMaster,source_node)
    Node.lookup(source_pid,destination_node)
    :timer.sleep(1000)

    maximum_hop = Stage.getmax(MyStage);
    IO.puts("The above request completed in hops: #{maximum_hop}")

    IO.puts("Sending all requests to calculate maximum hops in network for any routing...")

    Stage.send_request(MyStage,numReq);

    :sys.get_state(MyStage, :infinity)
    maximum_hop = Stage.getmax(MyStage);
    IO.puts("Maximum Hops done: #{maximum_hop}")
    #Enum.each(test_list, fn(i) ->
    #any_node = i
    #IO.puts "Node Name: #{any_node}"
    #node_pid = Master.lookup(MyMaster,any_node)
    #map_of_rand_node = Node.gettable(node_pid)

    #Enum.each 0..3, fn(i) ->
     # IO.puts "level: #{i}"
     # Enum.each map_of_rand_node[Integer.to_string(i)], fn {k,v} ->
     #   IO.puts "#{k} --> #{v}"
    #  end
    #end
    #end)


    #map = Node.gettable(Master.lookup(MyMaster,Enum.fetch!(node_list,4)))
    #Enum.each 0..3, fn(i) ->
     # IO.puts(i);
      #Enum.each map[Integer.to_string(i)], fn {k, v} ->
       # IO.puts "#{k} --> #{v}"
      #end
    #end
    #IO.puts map["0"]["A"]
  end

  def leading_match(key) do
    keys = [String.slice(key, 0..-2), String.slice(key, 0..-3), String.slice(key, 0..-4)]
    # IO.puts(keys)

    # Enum.each(keys, fn key ->
    # IO.puts(key)
    # end)
    #IO.puts(key)
    list = Master.get(MyMaster)
    Enum.reduce(keys, {"", 0}, fn key, {nearest, distance} ->
      {nearestloop, distanceloop} =
        Enum.reduce(list, {"", 0}, fn item, {nearest, distance} ->
          match_length = String.length(item) - String.length(String.trim_leading(item, key))

          if match_length > distance do
            {item, match_length}
          else
            {nearest, distance}
          end
        end)

      #IO.puts(key)
      #IO.puts(nearestloop)
      #IO.puts(distanceloop)

      if distanceloop > distance do
        if (distance == 0 && distanceloop == 4) || distanceloop < 4 do
          {nearestloop, distanceloop}
        else
          {nearest, distance}
        end
      else
        {nearest, distance}
      end
    end)
  end
  def hash_modulus(str_num) do
    num = :crypto.hash(:sha, str_num) |> Base.encode16()
    {int_num, _} = Integer.parse(num, 16)
    id = rem(int_num, :math.pow(2, 20) |> trunc)
    idhex = Integer.to_string(id, 16)
    length = String.length(idhex)
    range = (length - 4)..length
    idhexlen4 = String.slice(idhex, range)
    idstr = String.pad_leading(idhexlen4, 4, "0")
    check_id(idstr)
  end

  # makes sure all the ids are unique
  def check_id(id) do
    node_list = Master.get(MyMaster)
    if id in node_list do
      #IO.puts(id)
      {idint, _} = Integer.parse(id,16)
      idhex = Integer.to_string(idint + :rand.uniform(100),16)
      #IO.puts(idhex)
      length = String.length(idhex)
      range = (length - 4)..length
      idhexlen4 = String.slice(idhex, range)
      #IO.puts(idhexlen4)
      idstr = String.pad_leading(idhexlen4, 4, "0")
      check_id(idstr)
    else
      id
    end
  end

end
