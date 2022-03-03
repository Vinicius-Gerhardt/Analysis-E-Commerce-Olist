-- Utiliza��o do banco de dados: Brazilian E-Commerce Public Dataset by Olist (https://www.kaggle.com/olistbr/brazilian-ecommerce) 
-- Sistema de Banco de Dados: SQL Server

-- A padroniza��o dos dados para ocupar o menor espa�o poss�vel foi feita na importa��o dos dados para o SQL Server. Foi especificado os tipos de dados e identificado os menores n�meros de caracteres poss�veis.
-- Algumas linhas das colunas de datas encontravam-se em branco. Os c�digos abaixo definem na linha da coluna a palavra 'NULL' caso a coluna das datas esteja em branco.

SELECT * FROM olist_order_items_dataset

UPDATE olist_order_items_dataset
SET ["shipping_limit_date"] = null
WHERE ["shipping_limit_date"] = ' ' 

SELECT * FROM olist_orders_dataset

UPDATE olist_orders_dataset
SET ["order_estimated_delivery_date"] = null
WHERE ["order_estimated_delivery_date"] = ' '


--1) QUANTOS PAGAMENTOS FORAM EFETUADAS EM CADA TIPO DE PAGAMENTO? QUAIS TIPOS DE PAGAMENTOS APRESENTAM MAIOR E A MENOR REPRESENTATIVIDADE PARA A EMPRESA? 

SELECT ["payment_type"] , COUNT(["payment_type"]) AS 'N�mero de pagamentos efetuados'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]

-- A consulta retorna todos os tipos de pagamentos efetuados e quantas vezes foram efetuados esses tipos de pagamentos. Foram efetuados 103.886 pagamentos no total. 
-- 76.795 pagamentos foram efetuadas no cart�o de cr�dito, enquanto apenas 1.529 vendas foram efetuadas no cart�o de d�bito. O n�mero de pagamentos efetuados no cart�o de cr�dito representam 73,92% do n�mero total de pagamentos. Apenas 1,47% das pagamentos foram efetuadas na fun��o de d�bito.

SELECT SUM(["payment_value"]) AS 'Receita total'
FROM olist_order_payments_dataset

SELECT ["payment_type"],  SUM(["payment_value"]) AS 'Receita de cada fun��o de pagamento'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

SELECT ["payment_type"],  SUM(["payment_value"]) AS 'Receita de cada fun��o de pagamento'
FROM olist_order_payments_dataset
GROUP BY ["PAYMENT_TYPE"]
HAVING ["payment_type"] = 'debit_card'

-- Considerando todos os tipos de pagamentos, a empresa recebeu R$16.008.872,11
-- A receita proveniente dos pagamentos efetuados no cart�o de cr�dito � de R$ 12.542.084,18. No d�bito, apenas R$217.989,79. Os pagamentos efetuados no cart�o de cr�dito representam 78,34% da receita total da empresa (maior representatividade). Os pagamentos efetuados no d�bito representam apenas 1,36% da receita total da empresa (menor representatividade).

-- Prop�sito da Quest�o: � poss�vel calcular os tipos de pagamentos mais efetuados, os per�odos do ano que ocorreRAm mais vendas, os funcion�rios que efetuaram mais vendas, etc. Al�m disso, combinar esses fatores para ter respostas mais espec�ficas sobre a origem das receitas da empresa. Tamb�m � poss�vel realizar esse estudo com os custos.


--2) QUAL O VALOR M�XIMO EFETUADO EM CADA TIPO DE PAGAMENTO?

SELECT * FROM olist_order_payments_dataset

-- Como a coluna que indica os valores efetuados nas op��es de pagamentos est� classificada como tipo de dado nvarchar (caracteres), � necess�rio alterar para tipo de dados n�meros fracion�rios (float):

ALTER TABLE olist_order_payments_dataset
ALTER COLUMN ["payment_value"] float

SELECT ["payment_type"], MAX (["payment_value"]) AS 'M�dia dos tipos de pagamentos'
FROM olist_order_payments_dataset
GROUP BY ["payment_type"]

 -- A consulta retorna os valores m�ximos efetuados em cada tipo de pagamento. Na fun��o cr�dito, o valor m�ximo efetuado foi de R$ 13.664,08, enquanto que na fun��o d�bito, o valor m�ximo efetuado foi de apenas R$ 4.445,50.

 -- Prop�sito da Quest�o: O c�lculo do valor m�ximo ou m�nimo de vendas efetuadas em cada tipo de pagamento, regi�o ou categoria s�o algumas informa��es que podem ser �teis para a empresa entender caracter�sticas dos pagamentos.


--3) QUAL O VALOR DA RECEITA TOTAL DE VENDAS EFETUADAS NO CART�O DE CR�DITO REALIZADAS POR CONSUMIDORES DO ESTADO DE S�O PAULO? E A M�DIA DAS VENDAS?

-- As colunas necess�rias para �n�lise dos dados n�o est�o na mesma tabela. � necess�rio criar uma VIEW com dois INNER JOINs, de modo que agrupe dados de 3 tabelas diferentes.

SELECT * FROM olist_customers_dataset
SELECT * FROM olist_order_payments_dataset
SELECT * FROM olist_orders_dataset

CREATE VIEW PAYMENT_CUSTOMER_STATE_CITY AS
SELECT c.["customer_state"], c.["customer_city"], o.["order_id"], o.["customer_id"], p.["payment_type"], p.["payment_value"]
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
INNER JOIN olist_order_payments_dataset p ON o.["order_id"] = p.["order_id"]

SELECT * FROM PAYMENT_CUSTOMER_STATE_CITY

SELECT ["payment_type"], SUM (["payment_value"]) AS 'Soma das vendas efetuadas no cart�o de cr�dito em SP'
FROM PAYMENT_CUSTOMER_STATE_CITY
WHERE ["customer_state"] = 'SP' 
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

-- A receita total dos pagamentos realizados somente no estado de S�o Paulo na op��o cart�o de cr�dito � de R$ 1.777.436,70
-- Este valor representa 14,11% de todos os pagamentos efetuados no cart�o de cr�dito.

SELECT ["payment_type"], AVG (["payment_value"]) AS 'Soma das vendas efetuadas no cart�o de cr�dito em SP'
FROM PAYMENT_CUSTOMER_STATE_CITY
WHERE ["customer_state"] = 'SP' 
GROUP BY ["payment_type"]
HAVING ["payment_type"] = 'credit_card'

-- O valor m�dio dos pagamentos realizados somente no estado de S�o Paulo na op��o cart�o de cr�dito � de R$ 147,04

-- Prop�sito da Quest�o: Demonstrar que � poss�vel especificar as caracter�sticas sobre as vendas. � vi�vel fazer diversas combina��es para entender o comportamento de onde e como s�o gerados as receitas da empresa.


--4) QUAIS AS 10 CATEGORIAS DE PRODUTOS QUE APRESENTARAM MAIOR RECEITA? QUAL OBTEVE MAIOR RECEITA?

SELECT * FROM olist_order_items_dataset

-- Alterar o tipo de dados da coluna "price" para n�meros fracion�rios:

ALTER TABLE olist_order_items_dataset
ALTER COLUMN """price""" float null 

-- Cria��o de VIEW para agrupar todos dados necess�rios para an�lise:

CREATE VIEW PRODUCT_CATEGORY_PRICE AS
SELECT i.["order_id"], i.["price"], i.["order_item_id"], p.["product_category_name"], p.["product_id"]
FROM olist_order_items_dataset i
INNER JOIN olist_products_dataset p ON i.["product_id"] = p.["product_id"]

SELECT TOP 10  ["product_category_name"], SUM(["price"]*["order_item_id"]) AS 'Receita total do produto'
FROM PRODUCT_CATEGORY_PRICE
GROUP BY ["product_category_name"]
ORDER BY SUM(["price"]*["order_item_id"]) desc

-- A consulta retorna as 10 categorias de produtos que mais geraram receita, assim como a receitas geradas.
-- A categoria que gerou maior receita foi a de beleza e sa�de, com um total de R$ 1.347.468,48. Representa 8,22% da receita total da empresa.

-- Prop�sito da Quest�o: Demonstrar que pode-se identificar os produtos/categorias/funcion�rios que mais geram receita e quanto essas receitas representam para a empresa. Tamb�m � poss�vel identificar aqueles que est�o gerando receitas abaixo do esperado.


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

-- Prop�sito da Quest�o: Demonstrar que mesmo que as informa��es necess�rias para realizar uma an�lise estejam em tabelas diferentes, � poss�vel agrupar essas informa��es e efetuar a an�lise de categorias espec�ficas de produtos, funcion�rios, consumidores, etc.


--6) QUAL A RECEITA TOTAL DOS PRODUTOS DA CATEGORIA DE PERFUMARIA EM MAR�O DE 2018?

SELECT ["product_category_name"], sum(["order_item_id"] * ["price"]) AS 'Receita Total Categoria Perfumaria em Mar�o de 2018'
FROM CATEGORY_ORDER_PRICE_SHIPPINGDATE
WHERE ["shipping_limit_date"] BETWEEN '2018-03-01 00:00:00' AND '2018-03-31 23:59:59'
GROUP BY ["product_category_name"]
HAVING ["product_category_name"] = 'perfumaria'

-- A receita total dos produtos da categoria Perfumaria no m�s de mar�o de 2018 foi de R$ 27.751,72. Representa 5,71% do total de receita da categoria perfumaria (R$497.743,00).

-- Prop�sito da Quest�o: Demonstrar a possibilidade de especifica��o na an�lise de dados. Entender a representatividade de cada categoria de produto para a empresa, assim como os per�odos mais representativos na receita desses produtos.


--7) QUAIS OS PRODUTOS MAIS CAROS DA CATEGORIA PERFUMARIA? RANKING DO MAIOR PARA MENOR.

SELECT DISTINCT ["product_id"],  ["product_category_name"], ["price"],
ROW_NUMBER() OVER (PARTITION BY ["product_category_name"] ORDER BY ["price"] DESC) AS 'NUMERO LINHA',
DENSE_RANK() OVER (PARTITION BY ["product_category_name"] ORDER BY ["price"] DESC) AS 'RANKING PRODUTOS DE PERFUMARIA POR PRE�O'
FROM PRODUCT_CATEGORY_PRICE
WHERE ["product_category_name"] = 'perfumaria'
ORDER BY ["price"] DESC

-- A consulta retorna um ranking dos produtos mais caros conforme o pre�o. O produto mais caro da categoria perfumaria custa R$ 689,90.

-- Prop�sito da Quest�o: O ranqueamento do pre�o de todos os produtos da empresa pode ser uma informa��o �til. Este tipo de c�digo pode ser feito para ranquear a receita gerada por cada funcion�rio, o sal�rio dos funcion�rios, os valores de mat�ria-prima, etc.


--8) IDENTIFICAR QUEM S�O OS CONSUMIDORES QUE EFETUARAM PAGAMENTOS ACIMA DA M�DIA. ORDENAR DO MAIOR PARA O MENOR.

SELECT ["customer_id"] , SUM (["payment_value"]) AS 'Pagamentos'
FROM PAYMENT_CUSTOMER_STATE_CITY
GROUP BY ["customer_id"]
HAVING SUM (["payment_value"]) > (SELECT AVG (["payment_value"]) FROM PAYMENT_CUSTOMER_STATE_CITY) 
ORDER BY SUM (["payment_value"]) DESC

-- A consulta retorna o ID dos 11.687 consumidores que efetuaram pagamentos para a empresa acima da m�dia dos pagamentos totais (R$154,35). A empresa conta com um total de 37.276 consumidores.

-- Prop�sito da quest�o: Demonstrar a possibilidade de compara��o de receitas/custos com m�dias ou outras medidas estat�sticas da empresa.


--9) IDENTIFICAR QUANTOS E QUEM S�O OS CONSUMIDORES RESIDENTES NA CIDADE DE BARUERI E QUE POSSUEM ZIP CODE COM O N�MERO FINAL 0.

SELECT COUNT (["customer_id"])
FROM olist_customers_dataset
WHERE ["customer_city"] = 'barueri' AND ["customer_zip_code_prefix"]  LIKE '%0'

SELECT ["customer_id"], ["customer_zip_code_prefix"], ["customer_city"], ["customer_state"]
FROM olist_customers_dataset
WHERE ["customer_city"] = 'barueri' AND ["customer_zip_code_prefix"]  LIKE '%0'

-- 54 consumidores residem na cidade de Barueri e possuem zip code com o n�mero final 0. A consulta retorna todos os cosumidores residentes na cidade de Barueri e que possuam zip code com o n�mero final 0.

-- Prop�sito da Quest�o: Demonstrar que � poss�vel identificar consumidores/produtos/funcion�rios que possuem caracter�stica espec�ficas.


--10) IDENTIFICAR QUEM S�O OS CONSUMIDORES RESIDENTES NA CIDADE DE BARUERI E QUE POSSUEM ZIP CODE COM O N�MERO FINAL 0 QUE EFETUARAM PAGAMENTOS MAIORES DO QUE R$50,00.

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

-- Apenas dois consumidores residentes em Barueri e com zip code de n�mero final 0 consumiram mais de R$50,00 em produtos da empresa. A consulta retorna o ID dos dois consumidores.

-- Prop�sito da Quest�o: Demonstrar que al�m de especificar informa��es contidas em qualquer tabela da empresa, � poss�vel realizar an�lises com n�meros fixados. 


-- As consultas acima tem o intuito de demonstrar como � poss�vel identificar produtos/consumidores/funcion�rios outras informa��es conforme as especifica��es desejadas. Tamb�m � poss�vel realizar compara��es de categorias, per�odos e entre outros para an�lise de dados.
-- Apesar de n�o ser uma ferramenta de visualiza��o de dados, o SQL Server responde diversas quest�es de neg�cio que podem ser utilizadas para tomada de decis�o.
-- Para visualiza��o de dados, utilizo a ferramenta Power BI. No documento Olist E-Commerce - SQL Server - Power BI, estruturo as tabelas necess�rias para responder quest�es de neg�cio no Power BI.






