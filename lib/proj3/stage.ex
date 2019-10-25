defmodule Stage do
  use GenServer
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def send_request(server,count) do
    GenServer.cast(server, {:send,count})
  end

  def getmax(server) do
    GenServer.call(server,{:getmax})
  end

  def savemax(server,val) do
    GenServer.cast(server,{:savemax,val})
  end

  def init(:ok) do
    {:ok, %{:max =>0}}
  end

  def handle_cast({:send,count},state) do
    node_list = Master.get(MyMaster)
    Enum.each node_list, fn node ->
      node_list_excl_self = node_list -- [node]
      source_pid = Master.lookup(MyMaster,node)
      Enum.each 0..count, fn _i ->
        rand_dest_node = Enum.random(node_list_excl_self)
        Node.lookup(source_pid,rand_dest_node)
      end
    end
    #Process.exit(MyMaster,:kill)
    {:noreply,state}
  end

  def handle_cast({:savemax,value}, state) do
    currentmax = state[:max]
    currentmax = max(value,currentmax)
    state = Map.put(state, :max, currentmax)
    {:noreply, state}
  end


  def handle_call({:getmax},_from,state) do
    {:reply,state[:max],state}
  end

end
