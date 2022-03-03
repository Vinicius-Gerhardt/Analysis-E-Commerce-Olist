-- Utilização do banco de dados: Brazilian E-Commerce Public Dataset by Olist (https://www.kaggle.com/olistbr/brazilian-ecommerce) 
-- Sistema de Banco de Dados: SQL Server

-- A padronização dos dados para ocupar o menor espaço possível foi feita na importação dos dados para o SQL Server. Foi especificado os tipos de dados e identificado os menores números de caracteres possíveis.
-- Algumas linhas das colunas de datas encontravam-se em branco. Os códigos abaixo definem na linha da coluna a palavra 'NULL' caso a coluna das datas esteja em branco.

SELECT * FROM olist_order_items_dataset

UPDATE olist_order_items_dataset
SET ["shipping_limit_date"] = null
WHERE ["shipping_limit_date"] = ' ' 

SELECT * FROM olist_orders_dataset

UPDATE olist_orders_dataset
SET ["order_estimated_delivery_date"] = null
WHERE ["order_estimated_delivery_date"] = ' '


--1) QUANTOS PAGAMENTOS FORAM EFETUADAS EM CADA TIPO DE PAGAMENTO? QUAIS TIPOS DE PAGAMENTOS APRESENTAM MAIOR E A MENOR REPRESENTATIVIDADE PARA A EMPRESA? 

SELECT ["payment_type"] , COUNT(["payment_type"]) AS 'Número de pagamentos efetuados'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]

-- A consulta retorna todos os tipos de pagamentos efetuados e quantas vezes foram efetuados esses tipos de pagamentos. Foram efetuados 103.886 pagamentos no total. 
-- 76.795 pagamentos foram efetuadas no cartão de crédito, enquanto apenas 1.529 vendas foram efetuadas no cartão de débito. O número de pagamentos efetuados no cartão de crédito representam 73,92% do número total de pagamentos. Apenas 1,47% das pagamentos foram efetuadas na função de débito.

SELECT SUM(["payment_value"]) AS 'Receita total'
FROM olist_order_payments_dataset

SELECT ["payment_type"],  SUM(["payment_value"]) AS 'Receita de cada função de pagamento'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

SELECT ["payment_type"],  SUM(["payment_value"]) AS 'Receita de cada função de pagamento'
FROM olist_order_payments_dataset
GROUP BY ["PAYMENT_TYPE"]
HAVING ["payment_type"] = 'debit_card'

-- Considerando todos os tipos de pagamentos, a empresa recebeu R$16.008.872,11
-- A receita proveniente dos pagamentos efetuados no cartão de crédito é de R$ 12.542.084,18. No débito, apenas R$217.989,79. Os pagamentos efetuados no cartão de crédito representam 78,34% da receita total da empresa (maior representatividade). Os pagamentos efetuados no débito representam apenas 1,36% da receita total da empresa (menor representatividade).

-- Propósito da Questão: É possível calcular os tipos de pagamentos mais efetuados, os períodos do ano que ocorreRAm mais vendas, os funcionários que efetuaram mais vendas, etc. Além disso, combinar esses fatores para ter respostas mais específicas sobre a origem das receitas da empresa. Também é possível realizar esse estudo com os custos.


--2) QUAL O VALOR MÁXIMO EFETUADO EM CADA TIPO DE PAGAMENTO?

SELECT * FROM olist_order_payments_dataset

-- Como a coluna que indica os valores efetuados nas opções de pagamentos está classificada como tipo de dado nvarchar (caracteres), é necessário alterar para tipo de dados números fracionários (float):

ALTER TABLE olist_order_payments_dataset
ALTER COLUMN ["payment_value"] float

SELECT ["payment_type"], MAX (["payment_value"]) AS 'Média dos tipos de pagamentos'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]

 -- A consulta retorna os valores máximos efetuados em cada tipo de pagamento. Na função crédito, o valor máximo efetuado foi de R$ 13.664,08, enquanto que na função débito, o valor máximo efetuado foi de apenas R$ 4.445,50.

 -- Propósito da Questão: O cálculo do valor máximo ou mínimo de vendas efetuadas em cada tipo de pagamento, região ou categoria são algumas informações que podem ser úteis para a empresa entender características dos pagamentos.


--3) QUAL O VALOR DA RECEITA TOTAL DE VENDAS EFETUADAS NO CARTÃO DE CRÉDITO REALIZADAS POR CONSUMIDORES DO ESTADO DE SÃO PAULO? E A MÉDIA DAS VENDAS?

-- As colunas necessárias para ánálise dos dados não estão na mesma tabela. É necessário criar uma VIEW com dois INNER JOINs, de modo que agrupe dados de 3 tabelas diferentes.

SELECT * FROM olist_customers_dataset
SELECT * FROM olist_order_payments_dataset
SELECT * FROM olist_orders_dataset

CREATE VIEW PAYMENT_CUSTOMER_STATE_CITY AS
SELECT c.["customer_state"], c.["customer_city"], o.["order_id"], o.["customer_id"], p.["payment_type"], p.["payment_value"]
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
INNER JOIN olist_order_payments_dataset p ON o.["order_id"] = p.["order_id"]

SELECT * FROM PAYMENT_CUSTOMER_STATE_CITY

SELECT ["payment_type"], SUM (["payment_value"]) AS 'Soma das vendas efetuadas no cartão de crédito em SP'
FROM PAYMENT_CUSTOMER_STATE_CITY
WHERE ["customer_state"] = 'SP' 
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

-- A receita total dos pagamentos realizados somente no estado de São Paulo na opção cartão de crédito é de R$ 1.777.436,70
-- Este valor representa 14,11% de todos os pagamentos efetuados no cartão de crédito.

SELECT ["payment_type"], AVG (["payment_value"]) AS 'Soma das vendas efetuadas no cartão de crédito em SP'
FROM PAYMENT_CUSTOMER_STATE_CITY
WHERE ["customer_state"] = 'SP' 
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

-- O valor médio dos pagamentos realizados somente no estado de São Paulo na opção cartão de crédito é de R$ 147,04

-- Propósito da Questão: Demonstrar que é possível especificar as características sobre as vendas. É viável fazer diversas combinações para entender o comportamento de onde e como são gerados as receitas da empresa.


--4) QUAIS AS 10 CATEGORIAS DE PRODUTOS QUE APRESENTARAM MAIOR RECEITA? QUAL OBTEVE MAIOR RECEITA?

SELECT * FROM olist_order_items_dataset

-- Alterar o tipo de dados da coluna "price" para números fracionários:

ALTER TABLE olist_order_items_dataset
ALTER COLUMN """price""" float null 

-- Criação de VIEW para agrupar todos dados necessários para análise:

CREATE VIEW PRODUCT_CATEGORY_PRICE AS
SELECT i.["order_id"], i.["price"], i.["order_item_id"], p.["product_category_name"], p.["product_id"]
FROM olist_order_items_dataset i
INNER JOIN olist_products_dataset p ON i.["product_id"] = p.["product_id"]

SELECT TOP 10  ["product_category_name"], SUM(["price"]*["order_item_id"]) AS 'Receita total do produto'
FROM PRODUCT_CATEGORY_PRICE
GROUP BY ["product_category_name"]
ORDER BY SUM(["price"]*["order_item_id"]) desc

-- A consulta retorna as 10 categorias de produtos que mais geraram receita, assim como a receitas geradas.
-- A categoria que gerou maior receita foi a de beleza e saúde, com um total de R$ 1.347.468,48. Representa 8,22% da receita total da empresa.

-- Propósito da Questão: Demonstrar que pode-se identificar os produtos/categorias/funcionários que mais geram receita e quanto essas receitas representam para a empresa. Também é possível identificar aqueles que estão gerando receitas abaixo do esperado.


--5) QUAL A RECEITA TOTAL DOS PRODUTOS DA CATEGORIA DE PERFUMARIA? 

CREATE VIEW CATEGORY_ORDER_PRICE_SHIPPINGDATE AS
SELECT pcp.["order_id"], pcp.["price"], pcp.["order_item_id"], pcp.["product_category_name"], i.["shipping_limit_date"]
FROM PRODUCT_CATEGORY_PRICE pcp
LEFT JOIN olist_order_items_dataset i ON pcp. ["order_id"] = i.["order_id"]

SELECT ["product_category_name"], SUM(["order_item_id"] * ["price"]) AS 'Receita Total Categoria Perfumaria'
FROM CATEGORY_ORDER_PRICE_SHIPPINGDATE
GROUP BY ["product_category_name"]
HAVING ["product_category_name"] = 'perfumaria'

-- A  receita total dos produtos da categoria de perfumaria foi de R$497.743,08. Representa apenas 3,03% da receita total (R$16.381.504,10)

-- Propósito da Questão: Demonstrar que mesmo que as informações necessárias para realizar uma análise estejam em tabelas diferentes, é possível agrupar essas informações e efetuar a análise de categorias específicas de produtos, funcionários, consumidores, etc.


--6) QUAL A RECEITA TOTAL DOS PRODUTOS DA CATEGORIA DE PERFUMARIA EM MARÇO DE 2018?

SELECT ["product_category_name"], sum(["order_item_id"] * ["price"]) AS 'Receita Total Categoria Perfumaria em Março de 2018'
FROM CATEGORY_ORDER_PRICE_SHIPPINGDATE
WHERE ["shipping_limit_date"] BETWEEN '2018-03-01 00:00:00' AND '2018-03-31 23:59:59'
GROUP BY ["product_category_name"]
HAVING ["product_category_name"] = 'perfumaria'

-- A receita total dos produtos da categoria Perfumaria no mês de março de 2018 foi de R$ 27.751,72. Representa 5,71% do total de receita da categoria perfumaria (R$497.743,00).

-- Propósito da Questão: Demonstrar a possibilidade de especificação na análise de dados. Entender a representatividade de cada categoria de produto para a empresa, assim como os períodos mais representativos na receita desses produtos.


--7) QUAIS OS PRODUTOS MAIS CAROS DA CATEGORIA PERFUMARIA? RANKING DO MAIOR PARA MENOR.

SELECT DISTINCT ["product_id"],  ["product_category_name"], ["price"],
ROW_NUMBER() OVER (PARTITION BY ["product_category_name"] ORDER BY ["price"] DESC) AS 'NUMERO LINHA',
DENSE_RANK() OVER (PARTITION BY ["product_category_name"] ORDER BY ["price"] DESC) AS 'RANKING PRODUTOS DE PERFUMARIA POR PREÇO'
FROM PRODUCT_CATEGORY_PRICE
WHERE ["product_category_name"] = 'perfumaria'
ORDER BY ["price"] DESC

-- A consulta retorna um ranking dos produtos mais caros conforme o preço. O produto mais caro da categoria perfumaria custa R$ 689,90.

-- Propósito da Questão: O ranqueamento do preço de todos os produtos da empresa pode ser uma informação útil. Este tipo de código pode ser feito para ranquear a receita gerada por cada funcionário, o salário dos funcionários, os valores de matéria-prima, etc.


--8) IDENTIFICAR QUEM SÃO OS CONSUMIDORES QUE EFETUARAM PAGAMENTOS ACIMA DA MÉDIA. ORDENAR DO MAIOR PARA O MENOR.

SELECT ["customer_id"] , SUM (["payment_value"]) AS 'Pagamentos'
FROM PAYMENT_CUSTOMER_STATE_CITY
GROUP BY ["customer_id"]
HAVING SUM (["payment_value"]) > (SELECT AVG (["payment_value"]) FROM PAYMENT_CUSTOMER_STATE_CITY) 
ORDER BY SUM (["payment_value"]) DESC

-- A consulta retorna o ID dos 11.687 consumidores que efetuaram pagamentos para a empresa acima da média dos pagamentos totais (R$154,35). A empresa conta com um total de 37.276 consumidores.

-- Propósito da questão: Demonstrar a possibilidade de comparação de receitas/custos com médias ou outras medidas estatísticas da empresa.


--9) IDENTIFICAR QUANTOS E QUEM SÃO OS CONSUMIDORES RESIDENTES NA CIDADE DE BARUERI E QUE POSSUEM ZIP CODE COM O NÚMERO FINAL 0.

SELECT COUNT (["customer_id"])
FROM olist_customers_dataset
WHERE ["customer_city"] = 'barueri' AND ["customer_zip_code_prefix"]  LIKE '%0'

SELECT ["customer_id"], ["customer_zip_code_prefix"], ["customer_city"], ["customer_state"]
FROM olist_customers_dataset
WHERE ["customer_city"] = 'barueri' AND ["customer_zip_code_prefix"]  LIKE '%0'

-- 54 consumidores residem na cidade de Barueri e possuem zip code com o número final 0. A consulta retorna todos os cosumidores residentes na cidade de Barueri e que possuam zip code com o número final 0.

-- Propósito da Questão: Demonstrar que é possível identificar consumidores/produtos/funcionários que possuem característica específicas.


--10) IDENTIFICAR QUEM SÃO OS CONSUMIDORES RESIDENTES NA CIDADE DE BARUERI E QUE POSSUEM ZIP CODE COM O NÚMERO FINAL 0 QUE EFETUARAM PAGAMENTOS MAIORES DO QUE R$50,00.

SELECT TOP 10 * FROM olist_customers_dataset 
SELECT TOP 10 * FROM olist_order_items_dataset 
SELECT TOP 10 * FROM olist_orders_dataset

CREATE VIEW CONSUMERS_BARUERI_ZIPCODEFINAL0 AS
SELECT d.["order_id"],d.["customer_id"],i.["order_item_id"],i.["price"],c.["customer_zip_code_prefix"],c.["customer_city"]
FROM  olist_orders_dataset d
INNER JOIN olist_customers_dataset c ON d.["customer_id"] = c.["customer_id"]  
INNER JOIN olist_order_items_dataset i ON d.["order_id"] = i.["order_id"]
WHERE ["customer_city"] = 'barueri' AND ["customer_zip_code_prefix"]  LIKE '%0' 

SELECT * FROM CONSUMERS_BARUERI_ZIPCODEFINAL0

ALTER TABLE olist_order_items_dataset
ALTER COLUMN ["order_item_id"] INT

SELECT ["customer_id"] , SUM (["order_item_id"]*["price"]) 
FROM CONSUMERS_BARUERI_ZIPCODEFINAL0
GROUP BY ["customer_id"]
HAVING SUM (["order_item_id"]*["price"]) > 50

-- Apenas dois consumidores residentes em Barueri e com zip code de número final 0 consumiram mais de R$50,00 em produtos da empresa. A consulta retorna o ID dos dois consumidores.

-- Propósito da Questão: Demonstrar que além de especificar informações contidas em qualquer tabela da empresa, é possível realizar análises com números fixados. 


-- As consultas acima tem o intuito de demonstrar como é possível identificar produtos/consumidores/funcionários outras informações conforme as especificações desejadas. Também é possível realizar comparações de categorias, períodos e entre outros para análise de dados.
-- Apesar de não ser uma ferramenta de visualização de dados, o SQL Server responde diversas questões de negócio que podem ser utilizadas para tomada de decisão.
-- Para visualização de dados, utilizo a ferramenta Power BI. No documento Olist E-Commerce - SQL Server - Power BI, estruturo as tabelas necessárias para responder questões de negócio no Power BI.






