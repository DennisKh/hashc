defmodule Hashc do
  # @filename "./f_libraries_of_the_world.txt"
  # @filename "./e_so_many_books.txt"
  # @filename "./d_tough_choices.txt"
  @filename "./c_incunabula.txt"
  # @filename "./b_read_on.txt"
  # @filename "./a_example.txt"

  #    Hashc.fileread
  def fileread do
    stream = File.stream!(@filename)
    content =
      stream
      |> Stream.map(&String.trim/1)
      |> Enum.to_list
      |> Enum.chunk(2)
    [[library_info, books_score] | libraries] = content
    [books_count, library_count, days] = split(library_info)
    {:ok, book_id_pid} = Agent.start(fn -> 0 end)
    books_score_index =
      split(books_score)
      |> Enum.into(%{}, fn v ->
        {Agent.get_and_update(book_id_pid, fn state -> {state, state + 1} end), String.to_integer(v)}
      end)
    Agent.stop(book_id_pid)
    # write_result(library_count)
    {:ok, id_pid} = Agent.start(fn -> 0 end)
    final =
      Enum.reduce(libraries, [], fn [str1, book_number], acc ->
        books_ids = sort_by_scope_and_get_book_id(books_score_index, split(book_number))
        [library_books_count, reg_days, book_per_day] = split(str1)
        count = max_scan_library_books(days, reg_days, book_per_day)
        result =
          %{
            id: Agent.get_and_update(id_pid, fn state -> {state, state + 1} end),
            books: books_ids,
            score: calculatre_score(books_ids, count, books_score_index),
            count: count
          }

        [result | acc]
      end)
    Agent.stop(id_pid)
    final_data = Enum.sort(final, fn i, y -> i.score >= y.score end)
    {:ok, _} = Agent.start(fn -> [] end, name: :readed_books)
    perfection = ideal_result(books_score_index, final_data, [])
    write_result(length(perfection))
    Enum.each(perfection, fn %{books: books, id: id, count: count} ->
      write_result("#{id} #{length(books)}")
      write_result(Enum.join(books, " "))
    end)
  end

  def ideal_result(books_score_index, [], ideal_list) do
    ideal_list
  end

  def ideal_result(books_score_index, final_data, ideal_list) do
    [%{books: books, id: id, count: count} = ideal_item | other] = final_data
    Agent.update(:readed_books, fn state -> ([Enum.take(books, count) | state] |> Enum.uniq) end)
    tail =
      Enum.reduce(other, [], fn %{books: other_books, id: other_id, count: other_count}, acc ->
        left_books = other_books -- Agent.get(:readed_books, fn state -> state end)
        books_ids = sort_by_scope_and_get_book_id(books_score_index, left_books)
        result =
          %{
            id: other_id,
            books: books_ids,
            score: calculatre_score(books_ids, other_count, books_score_index),
            count: other_count
          }

        [result | acc]
      end)
      |> Enum.sort(fn i, y -> i.score >= y.score end)
    ideal_result(books_score_index, tail, List.insert_at(ideal_list, -1, ideal_item))
  end

  def max_scan_library_books(all_days, reg_days, book_per_day) do
    (to_int(all_days) - to_int(reg_days)) * to_int(book_per_day)
  end

  def sort_by_scope_and_get_book_id(books_score_index, books_list) do
    Enum.reduce(books_list, [], fn book_id, acc ->
      score = Map.get(books_score_index, book_id)
      [{score, book_id} | acc]
    end)
    |> Enum.sort(&(&1 > &2))
    |> Keyword.values
  end

  def calculatre_score(book_list, count, books_score_index) do
    Enum.take(book_list, count)
    |> Enum.reduce(0, fn i, acc ->
      acc + (Map.get(books_score_index, to_int(i)) |> to_int)
    end)
  end

  def write_result(str) do
    {:ok, file} =
      "./result.txt"
      |> File.open([:append])

    IO.binwrite(file, "#{str}\n")
    File.close(file)
  end
  def split(data) do
    String.split(data, " ")
  end
  def to_int(str) do
    String.to_integer("#{str}")
  end
end
