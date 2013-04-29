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
    lc x inlist document do 
      x.prefix("  " <> x.prefix).meta(
        Keyword.put x.meta, :nesting, Keyword.get(x.meta, :nesting, 0)+1
      )
    end
  end
end
