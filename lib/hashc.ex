defmodule Hashc do
  @filename
  def fileread do
    stream = File.stream!(@filename)
    fixed_contents = stream
    |> Enum.map(&String.trim/1)
  end
end
