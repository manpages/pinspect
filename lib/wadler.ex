defmodule Wadler do
  @moduledoc """
  Elixir pretty printing module inspired
  by Philip Wadler.
  """

  # Records to work with variant document representation
  # Those are generalized by `docentity` type.
  # Note that function that returns atom NIL is called `null`
  @type docentity :: TEXT.t | CONCAT.t | UNION.t | NEST.t | NIL | LINE
  defrecord TEXT, string: ""
  defrecord CONCAT, left: nil, right: nil
  defrecord UNION, left: nil, right: nil
  defrecord NEST, indent: 1, rest: nil

  # Records that represent finalized entities in a document
  # Those are generalized by `docfactor` type.
  @type docfactor :: Text.t | Line.t | Nil
  defrecord Text, string: "", rest: nil
  defrecord Line, indent: 0,  rest: nil

  # Functional interface to `docentity` records
  @spec null() :: NIL
  def null, do: NIL
  @spec concat(docentity, docentity) :: CONCAT.t
  def concat(x, y), do: CONCAT[left: x, right: y]
  @spec concat(non_neg_integer, docentity) :: NEST.t
  def nest(i, x), do: NEST[indent: i, rest: x]
  @spec text(binary) :: TEXT.t
  def text(s), do: TEXT[string: s]
  @spec line() :: LINE
  def line, do: LINE

  @spec group(docentity) :: UNION.t
  def group(x), do: UNION[left: flatten(x), right: x]

  # Helpers
  @spec s(docentity, docentity) :: CONCAT.t
  def s(x, y), do: concat(x, concat(text(" "), y))
  @spec s(docentity, docentity) :: CONCAT.t
  def n(x, y), do: concat(x, concat(line, y))
  @spec s(docentity, docentity) :: CONCAT.t
  def sn(x, y), do: concat(x, concat(UNION[left: text(" "), right: line], y))

  @spec folddoc( ((docentity, [docentity]) -> docentity), [docentity]) :: docentity
  def folddoc(_, []), do: null
  def folddoc(_, [doc]), do: doc
  def folddoc(f, [d|ds]), do: f.(d, folddoc(f, ds))

  @spec spread(docentity) :: docentity
  def spread(doc), do: folddoc(fn(x, d) -> s(x,d) end, doc)
  @spec stack(docentity) :: docentity
  def stack(doc),  do: folddoc(fn(x, d) -> n(x,d) end, doc)

  # Collapse a list of documents into a reasonably formatted document
  @spec fill([docentity]) :: docentity
  def fill([]), do: NIL
  def fill([doc]), do: doc
  def fill([x|[y|docs]]) do
    UNION[left:  s(flatten(x), fill( [flatten(y)|docs] )),
          right: n(x, fill( [y|docs] ))]
  end
  
  @spec bracket(binary, docentity, binary) :: docentity
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
  @spec pretty(non_neg_integer, docentity) :: binary
  def pretty(width, document), do: layout best(width, 0, document)
  @spec pretty0(non_neg_integer, docentity) :: docfactor
  def pretty0(width, document), do: best width, 0, document
  @spec pretty1(docfactor) :: binary
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

  defp copy(_, 0), do: ""
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
