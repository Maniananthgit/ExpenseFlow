from datetime import date


def test_budget_workflow_and_calculations(client, auth_headers):
    # Fetch expense category
    cats_resp = client.get("/api/v1/categories?type=EXPENSE", headers=auth_headers)
    assert cats_resp.status_code == 200
    expense_cat = cats_resp.json()[0]

    today = date.today()
    month = today.month
    year = today.year

    # 1. Create budget: 5000.00
    b_resp = client.post(
        "/api/v1/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_cat["id"],
            "amount": 5000.00,
            "month": month,
            "year": year,
        },
    )
    assert b_resp.status_code == 201
    budget = b_resp.json()
    assert float(budget["amount"]) == 5000.00
    assert float(budget["spent_amount"]) == 0.0
    assert float(budget["remaining_amount"]) == 5000.00
    assert budget["utilization_percentage"] == 0.0
    assert budget["is_exceeded"] is False

    # 2. Add expense transaction of 3500.00 (Example from requirements: 70% utilization)
    tx_resp = client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": expense_cat["id"],
            "amount": 3500.00,
            "type": "EXPENSE",
            "description": "Lunch and dining",
            "transaction_date": str(today),
        },
    )
    assert tx_resp.status_code == 201

    # 3. Retrieve budget summary
    summary_resp = client.get(f"/api/v1/budgets?month={month}&year={year}", headers=auth_headers)
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert float(summary["total_budget"]) == 5000.00
    assert float(summary["total_spent"]) == 3500.00
    assert float(summary["total_remaining"]) == 1500.00
    assert summary["overall_utilization"] == 70.0

    b_item = summary["budgets"][0]
    assert float(b_item["spent_amount"]) == 3500.00
    assert float(b_item["remaining_amount"]) == 1500.00
    assert b_item["utilization_percentage"] == 70.0
    assert b_item["is_exceeded"] is False

    # 4. Add another expense of 2000.00 to exceed the budget (total spent: 5500.00)
    client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": expense_cat["id"],
            "amount": 2000.00,
            "type": "EXPENSE",
            "description": "Weekend party",
            "transaction_date": str(today),
        },
    )

    summary_resp2 = client.get(f"/api/v1/budgets?month={month}&year={year}", headers=auth_headers)
    b_exceeded = summary_resp2.json()["budgets"][0]
    assert float(b_exceeded["spent_amount"]) == 5500.00
    assert float(b_exceeded["remaining_amount"]) == -500.00
    assert b_exceeded["is_exceeded"] is True
    assert b_exceeded["utilization_percentage"] == 110.0

    # 5. Duplicate budget rejection
    dup_resp = client.post(
        "/api/v1/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_cat["id"],
            "amount": 10000.00,
            "month": month,
            "year": year,
        },
    )
    assert dup_resp.status_code == 400
    assert "already exists" in dup_resp.json()["detail"]
