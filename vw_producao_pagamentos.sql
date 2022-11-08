 /* 'PAGAMENTOS' */
 -- Criada  em: 29/08/2022
 -- Criada por: Daniel Lopes
 -- Objetivo: Dashboard de producao - PA's e pagamentos
 -- View desenvolvida para o Dashboard de Produção com dados fornecidos pela DNR

 create or replace view dw.vw_producao_pagamentos AS
 /*COMENTÁRIO ADICIONADO APENAS PARA SER TRACKEADO PELO GITHUB*/
with raw_pagamentos as (
select
	'PAGAMENTOS' as base,
	CONCAT(
	LPAD(extract(day 	from data),2,0), "/",
	LPAD(extract(month 	from data),2,0), "/",
	LPAD(extract(year 	from data),4,0)) 	as data,
	LPAD(extract(day 	from data),2,0) 	as dia,
	LPAD(extract(month 	from data),2,0) 	as mes,
	LPAD(extract(year 	from data),4,0) 	as ano,
	case
		when UPPER(administradora) like '%VOLK%%' then   'VOLKSWAGEN'
		when UPPER(administradora) like '%MAGAL%%' then  'MAGALU'
		when UPPER(administradora) like '%SANTAN%%' then 'SANTANDER'
		when UPPER(administradora) like '%BANRI%%' then  'BANRISUL'
		when UPPER(administradora) like '%CHEVR%%' then  'CHEVROLET'
	else TRIM(UPPER(administradora)) end as administradora,
	case
		when descricao_despesa like ('%%COMPRA%%') then 'COMPRA DE COTA'
		else 'TAXAS' end as descricao_despesa,
	/*---------------------------------------------------*/
	case
		when chave is null and grupo is not null
			then concat(cast(grupo as unsigned), cast(cota as unsigned), cast(versao as unsigned))
		when chave is null and grupo is null
			then cpf_cnpj
	else chave end as chave,
	/*---------------------------------------------------*/	
	cpf_cnpj,
	(valor + valor) / valor as teste,
	((valor + 2) - valor) as teste_b
	valor
from
	stg.prd_pagamentos),

pagamentos_agg as (
select
	base,
	CAST(CONCAT(ano, "-", mes, "-", dia) AS DATE) as dt,
	data,
	ano,
	mes,
	dia,
	administradora,
	descricao_despesa,
	RANK() OVER (PARTITION BY mes, administradora ORDER BY data ASC) as ord_dia_mes,
	count(chave)		as cotas,
	sum(valor) 			as valor
from
	raw_pagamentos
-- where descricao_despesa = 'COMPRA DE COTA'
group by
	1,2,3,4,5,6,7,8),

pagamentos as (
select
	base,
	dt,
	data,
	ano,
	mes,
	dia,
	ord_dia_mes,
	-- RANK() OVER (PARTITION BY mes, administradora ORDER BY data ASC) as ord_dia_mes,
	administradora,
	descricao_despesa,
	cotas,
	SUM(cotas) OVER(PARTITION BY ANO, MES, administradora, descricao_despesa ORDER BY data ASC) 			as acumulado_cotas,
	ROUND(valor, 2) as valor ,
	ROUND(SUM(valor) OVER(PARTITION BY ANO, mes, administradora, descricao_despesa ORDER BY data ASC),2) 	as acumulado_valor
from 
	pagamentos_agg
	order by MES desc, dia asc)

	select * from pagamentos
	/* VALIDACAO */
--  WHERE MES  = '08'
--   and ano = '2022'
--   and administradora  = 'VOLKSWAGEN' order by DIA