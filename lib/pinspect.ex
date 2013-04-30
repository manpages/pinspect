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

  def escape(other, char) do
    b = do_escape(other, char, <<>>)
    << char, b :: binary, char >>
  end 

  @compile {:inline, do_escape: 3}
  defp do_escape(<<>>, _char, binary), do: binary
  defp do_escape(<< char, t :: binary >>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, char >>) 
  end 
  defp do_escape(<<?#, ?{, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?#, ?{ >>) 
  end 
  defp do_escape(<<?\a, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?a >>) 
  end 
  defp do_escape(<<?\b, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?b >>) 
  end 
  defp do_escape(<<?\d, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?d >>) 
  end 
  defp do_escape(<<?\e, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?e >>) 
  end 
  defp do_escape(<<?\f, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?f >>) 
  end 
  defp do_escape(<<?\n, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?n >>) 
  end 
  defp do_escape(<<?\r, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?r >>) 
  end 
  defp do_escape(<<?\\, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?\\ >>) 
  end 
  defp do_escape(<<?\t, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?t >>) 
  end 
  defp do_escape(<<?\v, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, ?\\, ?v >>) 
  end 
  defp do_escape(<<h, t :: binary>>, char, binary) do
    do_escape(t, char, << binary :: binary, h >>) 
  end
end

defimpl Binary.PInspect, for: BitString do
  import Binary.PInspect.Utils
  import Binary.DocList

  @moduledoc """
  Represents the binary either as a printable string with
  double quote characters escaped or as an Elixir binary
  representation.
  """

  def inspect(string, opts), do: do_inspect String.printable?(string), string, opts

  ## Printable strings
  
  defp do_inspect(true, string, _), do: escape string, ?"

  ## Bitstrings

  defp do_inspect(false, bitstring, opts) do
    "<<" <> each_bit(bitstring, Keyword.get(opts, :limit, :infinity)) <> ">>"
  end

  defp each_bit(_, 0) do
    "..."
  end

  defp each_bit(<<h, t :: bitstring>>, counter) when t != <<>> do
    integer_to_binary(h) <> "," <> each_bit(t, decrement(counter))
  end

  defp each_bit(<<h :: size(8)>>, _counter) do
    integer_to_binary(h)
  end

  defp each_bit(<<>>, _counter) do
    <<>>
  end

  defp each_bit(bitstring, _counter) do
    size = bit_size(bitstring)
    <<h :: size(size)>> = bitstring
    integer_to_binary(h) <> "::size(" <> integer_to_binary(size) <> ")"
  end

  defp decrement(:infinity), do: :infinity                                                                                                                                            
  defp decrement(counter),   do: counter - 1
end

defimpl Binary.PInspect, for: List do
  def inspect(_,_), do: "List"
end

defimpl Binary.PInspect, for: Atom do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end

defimpl Binary.PInspect, for: Number do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end

defimpl Binary.PInspect, for: Function do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end

defimpl Binary.PInspect, for: PID do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end

defimpl Binary.PInspect, for: Port do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end

defimpl Binary.PInspect, for: Reference do
  def inspect(thing, opts), do: Binary.Inspect.inspect(thing, opts)
end
