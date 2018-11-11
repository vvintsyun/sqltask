declare @UserCredit table (
Id int IDENTITY(1,1),
UserId int,
Credit numeric(18,2)
);
 
insert into @UserCredit
values (1, 20), (2, 25);
 
declare @UserPurchase table (
Id int IDENTITY(1,1),
UserId int,
Cost numeric(18,2),
DT date,
Name varchar(50)
);
 
insert into @UserPurchase
values
 (1, 5, '24.04.2016', 'sku1'),
 (1, 6, '19.04.2016', 'sku2'),
 (1, 7, '22.04.2016', 'sku3'),
 (1, 8, '04.04.2016', 'sku4'),
 (1, 4, '18.04.2016', 'sku5'),
 (1, 5, '18.04.2016', 'sku6'),
 (1, 2, '29.04.2016', 'sku7');
 insert into @UserPurchase
values
 (2, 5, '24.04.2016', 'sku1'),
 (2, 6, '19.04.2016', 'sku2'),
 (2, 7, '22.04.2016', 'sku3'),
 (2, 8, '04.04.2016', 'sku4'),
 (2, 4, '18.04.2016', 'sku5'),
 (2, 2, '29.04.2016', 'sku7');


WITH GetPurchases as ( 
	SELECT pur.userId, pur.dt, pur.name, pur.cost, 
	sum(cost) over(partition by userId order by dt desc, id desc) as moneySpent 
	FROM @UserPurchase pur 
) 
(SELECT pur.UserId, pur.DT, pur.Name, pur.cost as 'Purchase/Rest' 
	FROM GetPurchases pur, @UserCredit cr 
	WHERE cr.UserId = pur.userId AND MoneySpent <= cr.credit 
) 
UNION ALL 
(SELECT pur.UserId, pur.dt, pur.name, (cr.credit - MoneySpent + cost) as 'Purchase/Rest' 
	FROM GetPurchases pur, @UserCredit cr 
	WHERE cr.UserId = pur.userId AND MoneySpent > cr.credit AND NOT EXISTS( 
		SELECT MoneySpent FROM GetPurchases pur2 WHERE cr.UserId = pur2.userId AND pur2.MoneySpent > cr.credit AND pur2.MoneySpent < pur.MoneySpent 
	) 
) 
ORDER BY UserId asc, dt desc
