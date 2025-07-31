defmodule KVServer.Command do
  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples
      iex> KVServer.Command.parse("CREATE shopping\r\n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("CREATE  shopping   \r\n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("PUT shopping milk 1\r\n")
      {:ok, {:put, "shopping", "milk", "1"}}
      
      iex> KVServer.Command.parse("GET shopping milk\r\n")
      {:ok, {:get, "shopping", "milk"}}

      iex> KVServer.Command.parse("DELETE shopping eggs\r\n")
      {:ok, {:delete, "shopping", "eggs"}}

  Unknow commands or commands with the wrong number of
  arguments returns an error:

    iex> KVServer.Command.parse("UNKNOW shopping eggs\r\n")
    {:error, :unknow_command}

    iex> KVServer.Command.parse("GET shopping")
    {:error, :unknow_command}
  """

  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["PUT", bucket, item, amount] -> {:ok, {:put, bucket, item, amount}}
      ["GET", bucket, item] -> {:ok, {:get, bucket, item}}
      ["DELETE", bucket, item] -> {:ok, {:delete, bucket, item}}
      _ -> {:error, :unknow_command}
    end
  end

  @doc """
  Runs the given command.
  """
  def run(command)

  def run({:create, bucket}) do
    KV.Registry.create(KV.Registry, bucket)
    {:ok, "OK\r\n"}
  end

  def run({:get, bucket, item}) do
    lookup(bucket, fn pid ->
      value = KV.Bucket.get(pid, item)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, item, amount}) do
    lookup(bucket, fn pid ->
      KV.Bucket.put(pid, item, amount)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, item}) do
    lookup(bucket, fn pid ->
      KV.Bucket.delete(pid, item)
      {:ok, "OK\r\n"}
    end)
  end

  defp lookup(bucket, callback) do
    case KV.Registry.lookup(KV.Registry, bucket) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
