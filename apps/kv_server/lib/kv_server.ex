defmodule KVServer do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

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
    msg =
      with {:ok, data} <- read_line(client),
           {:ok, command} <- KVServer.Command.parse(data),
           do: KVServer.Command.run(command)

    write_line(client, msg)
    serve(client)
  end

  defp read_line(client) do
    :gen_tcp.recv(client, 0)
  end

  defp write_line(client, {:ok, data}) do
    :gen_tcp.send(client, data)
  end

  defp write_line(client, {:error, :unknow_command}) do
    :gen_tcp.send(client, "UNKNOW COMMAND\r\n")
  end

  defp write_line(_client, {:error, :closed}) do
    exit(:shutdown)
  end

  defp write_line(client, {:error, :not_found}) do
    :gen_tcp.send(client, "NOT FOUND\r\n")
  end

  defp write_line(client, {:error, error}) do
    :gen_tcp.send(client, "ERROR\r\n")
    exit(error)
  end
end
