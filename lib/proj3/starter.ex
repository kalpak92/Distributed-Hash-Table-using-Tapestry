defmodule Starter do
  def start(args) do
    [numNodes, numReq] = args

    {numNodes, _} = Integer.parse(numNodes)
    {numReq, _} = Integer.parse(numReq)

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

   Enum.each(1..numNodes, fn(i) ->
      node_name = Integer.to_string(i) |> hash_modulus()
      {parent, _count} = leading_match(node_name)

      {:ok,node_pid} = Node.start_link("Dynamic", node_name,parent,[])
      Node.update_parent(node_pid,node_name,parent)
    end)

    :timer.sleep(1000)

    #node_list = Master.get(MyMaster)

    IO.puts("Sending all requests to calculate maximum hops in network for any routing...")

    Stage.send_request(MyStage,numReq);

    :sys.get_state(MyStage, :infinity)
    maximum_hop = Stage.getmax(MyStage);
    IO.puts("Maximum Hops done: #{maximum_hop}")

  end

  def leading_match(key) do
    keys = [String.slice(key, 0..-2), String.slice(key, 0..-3), String.slice(key, 0..-4)]

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
      {idint, _} = Integer.parse(id,16)
      idhex = Integer.to_string(idint + :rand.uniform(100),16)
      length = String.length(idhex)
      range = (length - 4)..length
      idhexlen4 = String.slice(idhex, range)
      idstr = String.pad_leading(idhexlen4, 4, "0")
      check_id(idstr)
    else
      id
    end
  end

end
