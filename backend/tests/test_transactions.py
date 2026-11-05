from datetime import date


def test_transaction_crud_and_isolation(client, auth_headers, second_auth_headers):
    # 1. Fetch categories for user A
    cats_resp = client.get("/api/v1/categories", headers=auth_headers)
    assert cats_resp.status_code == 200
    categories = cats_resp.json()
    assert len(categories) > 0

    income_cat = next(c for c in categories if c["type"] == "INCOME")
    expense_cat = next(c for c in categories if c["type"] == "EXPENSE")

    # 2. Create Income Transaction
    tx_in_payload = {
        "category_id": income_cat["id"],
        "amount": 50000.00,
        "type": "INCOME",
        "description": "Monthly Salary",
        "transaction_date": str(date.today()),
    }
    tx_in_resp = client.post("/api/v1/transactions", headers=auth_headers, json=tx_in_payload)
    assert tx_in_resp.status_code == 201
    income_tx = tx_in_resp.json()
    assert float(income_tx["amount"]) == 50000.00
    assert income_tx["type"] == "INCOME"

    # 3. Create Expense Transaction
    tx_ex_payload = {
        "category_id": expense_cat["id"],
        "amount": 2500.50,
        "type": "EXPENSE",
        "description": "Weekly Groceries",
        "transaction_date": str(date.today()),
    }
    tx_ex_resp = client.post("/api/v1/transactions", headers=auth_headers, json=tx_ex_payload)
    assert tx_ex_resp.status_code == 201
    expense_tx = tx_ex_resp.json()
    assert float(expense_tx["amount"]) == 2500.50

    # 4. Get transactions list for User A
    list_resp = client.get("/api/v1/transactions", headers=auth_headers)
    assert list_resp.status_code == 200
    data = list_resp.json()
    assert data["total"] == 2
    assert len(data["items"]) == 2

    # 5. Filter by type
    filter_resp = client.get("/api/v1/transactions?type=EXPENSE", headers=auth_headers)
    assert filter_resp.status_code == 200
    assert filter_resp.json()["total"] == 1
    assert filter_resp.json()["items"][0]["id"] == expense_tx["id"]

    # 6. User Isolation: User B must NOT see User A's transactions
    b_list_resp = client.get("/api/v1/transactions", headers=second_auth_headers)
    assert b_list_resp.status_code == 200
    assert b_list_resp.json()["total"] == 0

    # User B cannot access User A's transaction by ID
    b_get_resp = client.get(f"/api/v1/transactions/{income_tx['id']}", headers=second_auth_headers)
    assert b_get_resp.status_code == 404

    # User B cannot delete User A's transaction
    b_del_resp = client.delete(f"/api/v1/transactions/{income_tx['id']}", headers=second_auth_headers)
    assert b_del_resp.status_code == 404

    # 7. Update transaction
    up_resp = client.put(
        f"/api/v1/transactions/{expense_tx['id']}",
        headers=auth_headers,
        json={"amount": 3000.00, "description": "Updated Groceries"},
    )
    assert up_resp.status_code == 200
    assert float(up_resp.json()["amount"]) == 3000.00
    assert up_resp.json()["description"] == "Updated Groceries"

    # 8. Delete transaction
    del_resp = client.delete(f"/api/v1/transactions/{expense_tx['id']}", headers=auth_headers)
    assert del_resp.status_code == 204

    # Verify deleted
    get_del = client.get(f"/api/v1/transactions/{expense_tx['id']}", headers=auth_headers)
    assert get_del.status_code == 404
