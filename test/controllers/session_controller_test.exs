defmodule Bep.SessionControllerTest do
  use Bep.ConnCase

  test "GET /users/new", %{conn: conn} do
    conn = get conn, user_path(conn, :new)
    assert html_response(conn, 200) =~ "Great. Let's get started."
  end

  test "POST /users/create redirect to /login when email already linked to an account", %{conn: conn} do
    insert_user()
    conn = post conn, user_path(conn, :create, %{"user" => %{"email": "email@example.com", "password": "supersecret"}})
    assert html_response(conn, 302)
  end
end