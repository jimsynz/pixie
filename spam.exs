spam = fn(count)->
  IO.puts "building messages..."
  range = 0..count
  messages = Enum.map range, fn(i)->
    j = count - i
    Pixie.Message.Publish.init %{channel: "/spam", data: %{message: "Spam count remaining: #{j}"}}
  end
  IO.puts "publishing messages..."
  Pixie.Backend.publish messages
  IO.puts "done."
end

spam = fn
  0, _ ->
    Pixie.publish "/spam", %{message: "Spam count remaining: 0"}
  i, f ->
    Pixie.publish "/spam", %{message: "Spam count remaining: #{i}"}
    f.(i - 1, f)
end

spam.(1000, spam)
