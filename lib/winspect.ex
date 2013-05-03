defmodule WInspect do
  import Wadler

  def string(x) when is_binary(x), do: text Kernel.inspect(x)

  def list(x, i // 0) when is_list(x), do: nest i, bracket("[", list_do(x, i), "]")

  defp list_do([], _), do: null
  defp list_do([x|xs], i) when is_list(x) do
    group(n(list(x, i+2), list_do(xs, i)))
  end
  defp list_do([x|xs], i) do
    n(text(Kernel.inspect(x) <> ","), list_do(xs, i))
  end

  def helloabc do
    group(n(
      group(n(
        group(n(
          group(n(text("hello"), text("a"))),
        text("b"))),
      text("c"))),
    text("d")))
  end
end
