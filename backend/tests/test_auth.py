def test_register_user(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "newuser@example.com",
            "password": "SecurePassword123",
            "full_name": "New User",
            "currency": "INR",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "newuser@example.com"
    assert data["full_name"] == "New User"
    assert data["currency"] == "INR"
    assert "id" in data


def test_register_duplicate_email(client):
    user_payload = {
        "email": "dup@example.com",
        "password": "Password123!",
        "full_name": "Dup User",
        "currency": "USD",
    }
    resp1 = client.post("/api/v1/auth/register", json=user_payload)
    assert resp1.status_code == 201

    resp2 = client.post("/api/v1/auth/register", json=user_payload)
    assert resp2.status_code == 400
    assert "already exists" in resp2.json()["detail"]


def test_login_success_and_me(client, auth_headers):
    # Verify /me endpoint
    resp = client.get("/api/v1/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["email"] == "testuser@example.com"


def test_login_invalid_credentials(client):
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "wrong@example.com", "password": "wrongpassword"},
    )
    assert resp.status_code == 401


def test_update_profile(client, auth_headers):
    resp = client.put(
        "/api/v1/auth/me",
        headers=auth_headers,
        json={"full_name": "Updated Name", "currency": "USD"},
    )
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "Updated Name"
    assert resp.json()["currency"] == "USD"


def test_change_password(client, auth_headers):
    resp = client.post(
        "/api/v1/auth/change-password",
        headers=auth_headers,
        json={"current_password": "Password123!", "new_password": "NewSecretPassword456"},
    )
    assert resp.status_code == 200
    assert "updated successfully" in resp.json()["message"]

    # Test login with new password
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "testuser@example.com", "password": "NewSecretPassword456"},
    )
    assert login_resp.status_code == 200
