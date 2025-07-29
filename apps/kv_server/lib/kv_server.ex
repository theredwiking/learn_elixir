defmodule KVServer do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port: #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(client) do
    client
    |> read_line()
    |> write_line(client)
    serve(client)
  end

  defp read_line(client) do
    #{:ok, data} = :gen_tcp.recv(client, 0)  
    case :gen_tcp.recv(client, 0) do
      {:ok, data} -> 
        data
      {:error, :closed} -> :gen_tcp.close(client)
    end
  end

  defp write_line(data, client) do
    :gen_tcp.send(client, data)
  end
end
