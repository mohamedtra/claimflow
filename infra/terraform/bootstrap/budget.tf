# Budget mensuel avec alertes par e-mail. Les crédits sont exclus du calcul : sinon ils
# compensent la consommation, le coût affiché reste à zéro et aucune alerte ne part avant
# l'épuisement des crédits. Ici, l'alerte reflète ce que l'environnement consomme réellement.
resource "aws_budgets_budget" "mensuel" {
  name         = "claimflow-mensuel"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_mensuel_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit = false
    include_refund = false
  }

  dynamic "notification" {
    for_each = [20, 50, 100]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.email_alertes]
    }
  }

  # Prévision : prévient avant le dépassement, quand la tendance du mois l'annonce.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.email_alertes]
  }
}
