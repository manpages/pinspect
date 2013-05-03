defmodule Wadler do
  @moduledoc """
  Elixir pretty printing module inspired
  by Philip Wadler.
  """

  # In the two next sections records `NIL`, `LINE` and `Nil` are 
  # introduced purely for homogenity of used entities

  # Records to work with variant document representation
  # Those are generalized by `docset` type.
  defrecord TEXT, string: ""
  defrecord CONCAT, left: nil, right: nil
  defrecord UNION, left: nil, right: nil
  defrecord NEST, indent: 1, rest: nil
  defrecord NIL, phony: 1
  defrecord LINE, phony: 1

  # Records to carry data in the final document representation
  # Those are generalized by `document` type.
  defrecord Text, string: "", rest: nil
  defrecord Line, indent: 0,  rest: nil
  defrecord Nil, phony: 1


  def pretty(width, document), do: layout best(width, 0, document)

  defp layout(Nil[]), do: ""
  defp layout(Text[string: s, rest: x]), do: s <> layout x
  defp layout(Line[indent: i, rest: x]), do: "\n" <> String.duplicate " ", i <> layout x


  # Choosing best layout
  defp best(width, start_pos, document), do: dobest width, start_pos, [{0,document}]

  # Best layout of \varempty is nil
  defp dobest(_, _, []), do: nil
  # Ignore NIL layout
  defp dobest(w, k, [{_,NIL[]}|z]), do: dobest w,k,z
  # Expand CONCAT into two candidates
  defp dobest(w, k, [{i,CONCAT[left: x, right: y]}|z]) do 
    dobest w,k,[{i,x}|[{i,y}|z]]
  end
  # Get indentation information from NEST and move on
  defp dobest(w, k, [{i,NEST[indent: j, rest: x]}|z]) do 
    dobest w,k,[{i+j,x}|z]
  end
  # Factor out TEXT and move caret accordingly
  defp dobest(w, k, [{_,TEXT[string: s]}|z]) do 
    Text[string: s, rest: dobest w, k+String.length(s), z]
  end
  # Factor out LINE and make the indentation be initial caret position on the new line
  defp dobest(w, _, [{i,LINE[]}|z]) do
    Line[indent: i, rest: dobest w, i, z]
  end
  # Choose better alternative from UNION
  defp dobest(w, k, [{i,UNION[left: x, right: y]}|z]) do
    better w, k, dobest(w,k,[{i,x}|z]), dobest(w,k,[{i,y}|z])
  end

  defp better(w, k, x, y), do: if fits?(w-k, x), do: x, else: y

  defp fits?(delta, _) when delta<0,  do: false
  defp fits?(_____, Nil),             do: true
  defp fits?(_____, Line[]),          do: true 
  defp fits?(delta, Text[string: s,
                           rest: x]), do: fits? delta - String.length(s), x
end
