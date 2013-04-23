defprotocol Binary.PInspect do
  @moduledoc """
  Draft code for pretty printing protocol.
  To be merged with Elixir code base later.
  """

  @only [BitString, List, Tuple, Atom, Number, Function, PID, Port, Reference]

  def inspect(thing, opts)
end

defimpl Binary.PInspect, for: BitString do
  def inspect(_,_), do: "BitString"
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
