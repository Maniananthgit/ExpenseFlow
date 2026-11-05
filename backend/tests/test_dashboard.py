from datetime import date


def test_dashboard_analytics(client, auth_headers):
    # Setup income & expense
    cats = client.get("/api/v1/categories", headers=auth_headers).json()
    inc_cat = next(c for c in cats if c["type"] == "INCOME")
    exp_cat = next(c for c in cats if c["type"] == "EXPENSE")

    today = date.today()
    # Income: 100,000
    client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": inc_cat["id"],
            "amount": 100000.00,
            "type": "INCOME",
            "description": "Primary Salary",
            "transaction_date": str(today),
        },
    )

    # Expense: 30,000
    client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": exp_cat["id"],
            "amount": 30000.00,
            "type": "EXPENSE",
            "description": "Rent and Utilities",
            "transaction_date": str(today),
        },
    )

    # Dashboard summary
    summary_resp = client.get("/api/v1/dashboard/summary", headers=auth_headers)
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert float(summary["total_income"]) == 100000.00
    assert float(summary["total_expenses"]) == 30000.00
    assert float(summary["current_balance"]) == 70000.00
    assert float(summary["monthly_savings"]) == 70000.00
    assert summary["savings_rate"] == 70.0
    assert len(summary["recent_transactions"]) == 2

    # Category breakdown
    breakdown_resp = client.get("/api/v1/dashboard/category-breakdown", headers=auth_headers)
    assert breakdown_resp.status_code == 200
    b_data = breakdown_resp.json()
    assert len(b_data["income_categories"]) == 1
    assert len(b_data["expense_categories"]) == 1
    assert float(b_data["expense_categories"][0]["total_amount"]) == 30000.00

    # Monthly trends
    trends_resp = client.get("/api/v1/dashboard/monthly", headers=auth_headers)
    assert trends_resp.status_code == 200
    trends = trends_resp.json()["trends"]
    assert len(trends) == 12

