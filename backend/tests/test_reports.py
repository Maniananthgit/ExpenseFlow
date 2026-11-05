from datetime import date


def test_reports_and_csv_export(client, auth_headers):
    cats = client.get("/api/v1/categories", headers=auth_headers).json()
    inc_cat = next(c for c in cats if c["type"] == "INCOME")
    exp_cat = next(c for c in cats if c["type"] == "EXPENSE")

    today = date.today()
    # Add income & expense
    client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": inc_cat["id"],
            "amount": 75000.00,
            "type": "INCOME",
            "description": "Consulting Income",
            "transaction_date": str(today),
        },
    )
    client.post(
        "/api/v1/transactions",
        headers=auth_headers,
        json={
            "category_id": exp_cat["id"],
            "amount": 15000.00,
            "type": "EXPENSE",
            "description": "Equipment Purchase",
            "transaction_date": str(today),
        },
    )

    # Monthly report
    m_resp = client.get(f"/api/v1/reports/monthly?month={today.month}&year={today.year}", headers=auth_headers)
    assert m_resp.status_code == 200
    m_data = m_resp.json()
    assert float(m_data["total_income"]) == 75000.00
    assert float(m_data["total_expense"]) == 15000.00
    assert float(m_data["net_savings"]) == 60000.00
    assert m_data["savings_rate"] == 80.0
    assert len(m_data["top_expenses"]) == 1

    # Yearly report
    y_resp = client.get(f"/api/v1/reports/yearly?year={today.year}", headers=auth_headers)
    assert y_resp.status_code == 200
    y_data = y_resp.json()
    assert float(y_data["total_income"]) == 75000.00
    assert float(y_data["total_expense"]) == 15000.00
    assert float(y_data["net_savings"]) == 60000.00
    assert len(y_data["monthly_trends"]) == 12

    # CSV Export
    csv_resp = client.get("/api/v1/reports/export", headers=auth_headers)
    assert csv_resp.status_code == 200
    assert "text/csv" in csv_resp.headers["content-type"]
    csv_text = csv_resp.text
    assert "Transaction ID,Date,Type,Category,Amount,Currency,Description,Created At" in csv_text
    assert "Consulting Income" in csv_text
    assert "Equipment Purchase" in csv_text

