defmodule WInspect do
  import Wadler

  def string(x) when is_binary(x), do: text Kernel.inspect(x)

  def list(x) when is_list(x), do: bracket("[", list_do(x), "]")

  defp list_do([]), do: null
  defp list_do([x|xs]) when is_list(x) do
    concat(list(x), list_do(xs))
  end
  defp list_do([x]) do
    text(Kernel.inspect(x))
  end
  defp list_do([x|xs]) do
    group(n(text(Kernel.inspect(x) <> ","), list_do(xs)))
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
