defmodule Master do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def put(server, new_node, node_pid) do
    GenServer.cast(server, {:put, new_node, node_pid})
  end

  def get(server) do
    GenServer.call(server, {:get})
  end

  def lookup(server, kash) do
    GenServer.call(server, {:lookup, kash})
  end
  def init(:ok) do
    {:ok, %{:node_list => [], :lookuptable => %{}}}
  end

  def handle_cast({:put, node, node_pid}, state) do
    node_list = state[:node_list]
    lookup_table = state[:lookuptable]
    lookup_table = Map.put(lookup_table, node, node_pid)
    node_list = node_list ++ [node]
    state = Map.put(state, :lookuptable, lookup_table)
    state = Map.put(state, :node_list, node_list)
    {:noreply, state}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state[:node_list], state}
  end

  def handle_call({:lookup, kash}, _from, state) do
    {:reply, state[:lookuptable][kash], state}
  end

end
