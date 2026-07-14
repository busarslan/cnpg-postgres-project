# CNPG operator kurulumu 
helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm install cnpg cloudnative-pg/cloudnative-pg --namespace cnpg-system --create-namespace
