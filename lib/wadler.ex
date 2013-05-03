defmodule Wadler do
  @moduledoc """
  Elixir pretty printing module inspired
  by Philip Wadler.
  """

  # In the two next sections records `NIL`, `LINE` and `Nil` are 
  # introduced purely for homogenity of used entities

  # Records to work with variant document representation
  # Those are generalized by `docentity` type.
  defrecord TEXT, string: ""
  defrecord CONCAT, left: nil, right: nil
  defrecord UNION, left: nil, right: nil
  defrecord NEST, indent: 1, rest: nil
  # NIL
  # LINE

  # Records that represent finalized entities in a document
  # Those are generalized by `docfactor` type.
  defrecord Text, string: "", rest: nil
  defrecord Line, indent: 0,  rest: nil
  # Nil

  # Functional interface to `docentity` records
  def null, do: NIL
  def concat(x, y), do: CONCAT[left: x, right: y]
  def nest(i, x), do: NEST[indent: i, rest: x]
  def text(s), do: TEXT[string: s]
  def line, do: LINE

  def group(x), do: UNION[left: flatten(x), right: x]

  # Helpers
  def s(x, y), do: concat(x, concat(" ", y))
  def n(x, y), do: concat(x, concat(line, y))
  def sn(x, y), do: concat(x, concat(UNION[left: text(" "), right: line], y))

  def folddoc(_, []), do: null
  def folddoc(_, [doc]), do: doc
  def folddoc(f, [d|ds]), do: f.(d, folddoc(f, ds))

  def spread(doc), do: folddoc(fn(x, d) -> s(x,d) end, doc)
  def stack(doc),  do: folddoc(fn(x, d) -> n(x,d) end, doc)

  # Collapse a list of documents into a reasonably formatted document
  def fill([]), do: NIL
  def fill([doc]), do: doc
  def fill([x|[y|docs]]) do
    UNION[left:  s(flatten(x), fill( [flatten(y)|docs] )),
          right: n(x, fill( [y|docs] ))]
  end
  
  def bracket(bracketl, doc, bracketr) do
    group(
      concat(
             text(bracketl), 
             concat(
                    nest(2, concat(line, doc)),
                    concat(line, text(bracketr))
             )
      )
    )
  end

  # The pretty printing functoion
  def pretty(width, document), do: layout best(width, 0, document)
  def pretty0(width, document), do: best width, 0, document
  def pretty1(finalized), do: layout finalized

  
  # Private functions

  # Flatten variant representation
  # Terminals
  defp flatten(NIL), do: NIL
  defp flatten(TEXT[string: s]), do: TEXT[string: s]
  defp flatten(LINE), do: TEXT[string: " "]
  #
  defp flatten(UNION[left: x, right: _]),  do: flatten x
  defp flatten(CONCAT[left: x, right: y]), do: CONCAT[left: flatten(x), right: flatten(y)]
  defp flatten(NEST[indent: i, rest: x]),  do: NEST[indent: i, rest: flatten(x)]

  # Laying out finalized document
  defp layout(Nil), do: ""
  defp layout(Text[string: s, rest: x]), do: s <> layout(x)
  defp layout(Line[indent: i, rest: x]), do: "\n" <> copy(" ", i) <> layout(x)

  defp copy(binary, 0), do: ""
  defp copy(binary, i), do: String.duplicate binary, i


  # Choosing best layout
  defp best(width, start_pos, document), do: dobest width, start_pos, [{0,document}]

  # Best layout of \varempty is Nil
  defp dobest(_, _, []), do: Nil
  # Ignore NIL layout
  defp dobest(w, k, [{_,NIL}|z]), do: dobest w,k,z
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
  defp dobest(w, _, [{i,LINE}|z]) do
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
