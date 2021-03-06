defmodule Bep.PageControllerTest do
  use Bep.ConnCase
  setup %{conn: conn} = config do
    if user = config[:login_as] do
      conn = assign(conn, :current_user, user)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Find the Best Quality"
  end

  @tag login_as: %{email: "email@example.com", id: 1}
  test "GET / redirect to /search when logged in", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302)
  end
end
