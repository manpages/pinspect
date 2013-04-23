defprotocol Binary.PInspect do
  @moduledoc """
  Draft code for pretty printing protocol.
  To be merged with Elixir code base later.
  """

  @only [BitString, List, Tuple, Atom, Number, Function, PID, Port, Reference]

  def inspect(thing, opts)
end

defmodule Binary.PInspect.Utils do
  @spec split_string(binary, integer) :: [binary]
  def split_string(string, width) do
    do_split_string string, width, []
  end

  @spec do_split_string(binary | :nil, integer, binary) :: [binary]
  defp do_split_string(nil, _, acc), do: Enum.reverse acc
  defp do_split_string(rem, width, acc) do 
    length = String.length rem 
    do_split_string String.slice(rem, width, length), width, [String.slice(rem, 0, width)|acc]
  end
end

defimpl Binary.PInspect, for: BitString do
  import Binary.PInspect.Utils
  def inspect(string, opts) do 
    offset = Keyword.get opts, :offset, 0
    width = if w = Keyword.get(opts, :width), do: w - offset, else: :infinity
    if width == :infinity do
      string = %b("#{string}")
    else 
      if width > 0 do
        [h|t] = Enum.reverse split_string(string, width)
        List.foldr t, %b("#{h}"), fn(x, acc) -> %b("#{x}") <> "<>\n" <> acc end
      else
        :erlang.error "PInspect length overflow"
      end
    end
  end
end

defimpl Binary.PInspect, for: List do
  def inspect(_,_), do: "List"
end

defimpl Binary.PInspect, for: Atom do
  def inspect(_,_), do: "Atom"
end

defimpl Binary.PInspect, for: Number do
  def inspect(_,_), do: "Number"
end

defimpl Binary.PInspect, for: Function do
  def inspect(_,_), do: "Function"
end

defimpl Binary.PInspect, for: PID do
  def inspect(_,_), do: "PID"
end

defimpl Binary.PInspect, for: Port do
  def inspect(_,_), do: "Port"
end

defimpl Binary.PInspect, for: Reference do
  def inspect(_,_), do: "Reference"
end
