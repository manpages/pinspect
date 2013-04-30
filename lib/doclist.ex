defmodule Binary.DocList do
  @moduledoc """
  `Binary.DocList` provides functions that 
  operate on document lists which in turn are 
  intermediate term representations for laying 
  out the documents by `Binary.PInspect` 
  implementations.
  """

  defrecord T, prefix: "", body: "", postfix: "", meta: Keyword.new()

  @spec wrap(binary, binary, [T.t]) :: [T.t]
  def wrap(left, right, [docfirst|doclines]) do
    docfirst = docfirst.body(left <> docfirst.body)
    [doclast|doclines] = Enum.reverse doclines
    doclast = doclast.body(doclast.body <> right)
    [docfirst|(Enum.reverse [doclast|doclines])]
  end

  @spec nest([T.t]) :: [T.t]
  def nest(document) do
    lc T[] = x inlist document do 
      x.prefix("  " <> x.prefix).meta(
        Keyword.put x.meta, :nesting, (x.meta[:nesting] || 0)+1
      )
    end
  end

  @spec print([T.t]) :: binary
  def print(document) do
    List.foldl document, "", fn(T[] = l,acc) -> acc <> l.prefix <> l.body <> l.postfix end
  end

  @spec flatten([T.t]) :: [T.t]
  def flatten([docfirst|doclines]) do
    List.foldl doclines, T.new, fn(T[] = l, T[] = acc) ->
      acc.body(acc.body<>l.body).postfix(l.postfix)
    end
  end
end
