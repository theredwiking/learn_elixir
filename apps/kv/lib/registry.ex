defmodule KV.Registry do
  use GenServer

  ### Client API
  
  @doc """
  Start the registry
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the buckets pid for `name` stored in `server` 

  Returns `{:ok, pid}` if the buckets exist, `:error` otherwise
  """ 
  #@spec lookup(GenServer.server(), String.t()) :: {:ok, pid()} | :error
  def lookup(server, name) do
    #GenServer.call(server, {:lookup, name})
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Ensures a bucket exist in `server` with given `name`
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ### Define GenServer Callbacks
  @impl true
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  #@impl true
  #def handle_call({:lookup, name}, _from, state) do
  #  {names, _} = state
  #  {:reply, Map.fetch(names, name), state}  
  #end

  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}
      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref) 
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in #{__MODULE__}: #{inspect(msg)}")
    {:noreply, state}
  end
end
