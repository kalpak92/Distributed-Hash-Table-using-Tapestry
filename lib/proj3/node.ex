defmodule Node do
  use GenServer

  def start_link(type,node_name,routing_table,opts) do
    GenServer.start_link(__MODULE__, [type,node_name,routing_table],opts)
  end


  def init(args) do
    [_type,self_id,routing_table] = args;
    {:ok,
      %{
        :parent => nil,
        :table => routing_table,
        :id => self_id
      }
  }
  end
end
