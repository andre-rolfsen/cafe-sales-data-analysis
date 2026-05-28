# Limpeza e Análise de Vendas de Café

Este projeto organiza uma base bruta de vendas, corrige valores inválidos e gera consultas exploratórias para entender faturamento, produtos e desempenho por local.

## Preparação da camada de trabalho
- Criação da tabela `cafe_sales_staging` a partir da base original `dirty_cafe_sales`.
- Cópia dos dados para preservar a tabela bruta e permitir tratamento sem alterar a origem.
- Criação de `cafe_sales_staging2` como apoio para medir erros antes e depois da limpeza.

Essa etapa isola a matéria-prima da análise e reduz o risco de perder o dado original.

## Qualidade dos dados
- Verificação de duplicatas com `ROW_NUMBER()` particionado por `transaction_id`.
- Padronização de valores inválidos, convertendo `ERROR`, `UNKNOWN` e campos vazios em `NULL`.

##  Regras de imputação
- Criação da tabela `prices` para mapear itens e preços válidos.
- Remoção de preços ambíguos para evitar preenchimentos incorretos.
- Preenchimento de campos ausentes com regras de negócio:
  - `price_per_unit = total_spent / quantity`
  - `item` a partir do preço conhecido
  - `price_per_unit` a partir do item conhecido
  - `total_spent = price_per_unit * quantity`
  - `quantity = total_spent / price_per_unit`

## Análise exploratória
- Identificação do período coberto pela base com `MIN(transaction_date)` e `MAX(transaction_date)`.
- Cálculo do faturamento total e da média diária.
- Medição da proporção de erros e valores faltantes.
- Agregações por mês, produto e localização.
