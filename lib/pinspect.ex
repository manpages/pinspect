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

  @moduledoc """
  Represents the binary either as a printable string with
  double quote characters escaped or as an Elixir binary
  representation.
  """

  def inspect(string, opts), do: do_inspect String.printable?(string), string, opts

  ## Printable strings
  
  defp do_inspect(true, string, opts) do 
    width = Keyword.get opts, :width, :infinity
    if width == :infinity do
      string = escape string, ?"
    else 
      [h|t] = split_string(string, width)
      List.foldl t, escape(h, ?"), fn(x, acc) -> acc <> "<>\n" <> escape(x, ?") end
    end
  end

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
  require Macro
  import Binary.PInspect.Utils

  @moduledoc """ 
  Represents the atom as an Elixir term. The atoms false, true
  and nil are simply quoted. Modules are properly represented
  as modules using the dot notation.

  Notice that in Elixir, all operators can be represented using
  literal atoms (`:+`, `:-`, etc).

  ## Examples

      iex> inspect(:foo)
      ":foo"
      iex> inspect(nil)
      "nil"
      iex> inspect(Foo.Bar)
      "Foo.Bar"

  """

  def inspect(false, _),  do: "false"
  def inspect(true, _),   do: "true"
  def inspect(nil, _),    do: "nil"
  def inspect(:"", _),    do: ":\"\""
  def inspect(Elixir, _), do: "Elixir"

  def inspect(atom, _) do
    binary = atom_to_binary(atom)

    cond do
      valid_atom_identifier?(binary) ->
        ":" <> binary
      valid_ref_identifier?(binary) ->
        Module.to_binary(atom)
      atom in Macro.binary_ops or atom in Macro.unary_ops ->
        ":" <> binary
      true ->
        ":" <> escape(binary, ?") 
    end 
  end

  # Detect if atom is an atom alias (Elixir-Foo-Bar-Baz)

  defp valid_ref_identifier?("Elixir" <> rest) do
    valid_ref_piece?(rest)
  end

  defp valid_ref_identifier?(_), do: false

  defp valid_ref_piece?(<<?-, h, t :: binary>>) when h in ?A..?Z do
    valid_ref_piece? valid_identifier?(t)
  end

  defp valid_ref_piece?(<<>>), do: true
  defp valid_ref_piece?(_),    do: false

  # Detect if string is a valid atom identifier

  defp valid_atom_identifier?(<<h, t :: binary>>) when h in ?a..?z or h in ?A..?Z or h == ?_ do
    case valid_identifier?(t) do
      <<>>   -> true
      <<??>> -> true
      <<?!>> -> true
      _      -> false
    end
  end

  defp valid_atom_identifier?(_), do: false

  defp valid_identifier?(<<h, t :: binary>>)
      when h in ?a..?z
      when h in ?A..?Z
      when h in ?0..?9
      when h == ?_ do
    valid_identifier? t
  end

  defp valid_identifier?(other), do: other
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
