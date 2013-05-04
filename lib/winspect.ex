defmodule WInspect do
  import Wadler
  alias Wadler, as: W

  def string(x) when is_binary(x), do: text Kernel.inspect(x)

  # "[ " <> inner(x) <> line <> "]"

  # list: newline outer(x) <> "," inner(xs)
  # else: newline inspect(x) <> "," inner(xs)

  def outer([]),                       do: text "[ ]"
  def outer(x) when is_list(x),        do: group outer_do(x)

  def outer1([]),                      do: text "[]"
  def outer1(x) when is_list(x),       do: group1 outer_do(x)

  defp outer_do(x) when is_list(x),    do: concat(text("[ "), concat(nest(2, inner(x)), concat(line, text("]"))))

  defp inner([]),                      do: null
  defp inner([x]) when is_list(x),     do: outer(x)
  defp inner([x|xs]) when is_list(x),  do: newline(concat(outer(x), text(",")), inner(xs))
  defp inner([x]),                     do: text Kernel.inspect(x)
  defp inner([x|xs]),                  do: newline(text(Kernel.inspect(x)<>","), inner(xs))

  def helloabc do
    group(newline(
      group(newline(
        group(newline(
          group(newline(text("hello"), text("a"))),
        text("b"))),
      text("c"))),
    text("d")))
  end

  def inspect_outer(w, x), do: IO.puts Wadler.pretty(w, outer(x))
  def inspect_outer1(w, x), do: IO.puts Wadler.pretty(w, outer1(x))
  
  def wadler(NIL),                              do: text "NIL"
  def wadler(LINE),                             do: text "LINE"
  def wadler(W.TEXT[string: s]),                do: text "TEXT[string: \""<>s<>"\"]"
  def wadler(W.UNION[]  = x),                   do: wadler_lr( "UNION[", x, "]")
  def wadler(W.CONCAT[] = x),                   do: wadler_lr("CONCAT[", x, "]")
  def wadler(W.NEST[indent: i, rest: x]),       do: concat( text("NEST[indent: "),
                                                    concat( text("#{i}"),
                                                    concat( nest(2,
                                                    concat(   line,
                                                    concat(   text("rest:"), wadler(x)))),
                                                            text("]") )))

  defp wadler_lr(lbr, x, rbr),                  do: concat( text(lbr),
                                                    concat( nest(2,
                                                    concat(   line,
                                                    concat(   text("left:"),  wadler( x.left)))),
                                                    concat( nest(2,
                                                    concat(   line,
                                                    concat(   text("right:"), wadler(x.right)))),
                                                            text(rbr) )))
end
