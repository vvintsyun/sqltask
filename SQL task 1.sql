declare @User table(
Id int,
LName nvarchar(200),
FName nvarchar(200),
Tel nvarchar(15) null
);
 
declare @Territorys table(
Id int,
Name nvarchar(200),
ParentID int null
);
 
declare @Network table(
Id int,
Name nvarchar(200)
);
 
declare @Shop table(
Id int,
Name nvarchar(200),
CityId int,
NetworkId int
);
 
declare @Plan table(
Id int,
UserId int,
ShopId int,
DT date,
[PlanMin] int
);
 
declare @Fact table(
Id int identity(1,1),
PlanId int,
FactFrom int,
FactTo int
);
 
insert into @User(Id, LName, FName, Tel)
values (1, 'Ivanov', 'Ivan', '+7(123)1231212'), (2, 'Ivanov', 'Vasily', null);
 
insert into @Territorys(Id, Name, ParentID)
values (1, 'Moscow', null),
 	   (2, 'Tver', 1),
 	   (3, 'Vladimir',   1),
 	   (4, 'Center', null),
 	   (5, 'Perm', 4),
 	   (6, 'Orel', 4);
 
insert into @Network(Id, Name)
values (1, 'ABK'),
 	   (2, 'Diksika'),
 	   (3, 'Orion');
 
insert into @Shop(Id, Name, CityId, NetworkId)
values (1, 'Shop1', 2, 1),
 	   (2, 'Shop2', 2, 1),
 	   (3, 'Shop3', 2, 1),
 	   (4, 'Shop4', 2, 2),
 	   (5, 'Shop5', 2, 2),
 	   (6, 'Shop6', 3, 1),
 	   (7, 'Shop7', 3, 2),
 	   (8, 'Shop8', 5, 3),
 	   (9, 'Shop9', 5, 3),
 	   (10, 'Shop10', 5, 3),
 	   (11, 'Shop11', 6, 3);
 
 
insert into @Plan(Id, UserId, ShopId, DT, [PlanMin])
values (1, 1, 1, '01.04.2016', 60),
 (2, 1, 1, '02.04.2016', 70),
 (3, 1, 1, '03.04.2016', 60),
 (4, 1, 2, '01.04.2016', 30),
 (5, 1, 2, '02.04.2016', 180),
 (6, 1, 3, '01.04.2016', 120),
 (7, 1, 4, '01.04.2016', 60),
 (8, 1, 4, '02.04.2016', 90),
 (9, 1, 5, '01.04.2016', 60), 
 (10, 2, 6, '01.04.2016', 55),
 (11, 2, 6, '02.04.2016', 33),
 (12, 2, 6, '03.04.2016', 60),
 (13, 2, 7, '01.04.2016', 22),
 (14, 2, 7, '02.04.2016', 123),
 (15, 2, 8, '01.04.2016', 120),
 (16, 2, 9, '01.04.2016', 70),
 (17, 2, 10, '02.04.2016', 90),
 (18, 2, 11, '01.04.2016', 65);
 
 
insert into @Fact(PlanId, FactFrom, FactTo)
values (1, 0, 23),
 (2, 500, 600),
 (3, 33, 44),
 (4, 666, 785),
 (6, 1300, 1500),
 (7, 401, 480),
 (8, 720, 875),
 (10, 234, 432),
 (11, 1, 11),
 (12, 11, 111),
 (13, 22, 222),
 (15, 33, 333),
 (16, 44, 444);

WITH RawData AS ( 
	select region.id as RegionId, region.name as Region, city.id as CityId, city.name as City, network.id as NetworkId, network.name as Network, 
	sum(p.PlanMin) as PlanMinNetwork, coalesce(sum(f.FactTo)-sum(f.FactFrom),0) as FactMinNetwork
	from @Territorys region
	join @Territorys city on city.parentId = region.id
	join @Shop shop on shop.cityId = city.id
	join @Network network on shop.networkId = network.id
	join @Plan p on p.shopId = shop.id
	left join @Fact f on f.PlanId = p.Id
	WHERE region.parentId is NULL
	GROUP BY region.id, region.name, city.id, city.name, network.id, network.name 
) 
SELECT Region, FORMATMESSAGE('%d:%02d', sum(PlanMinNetwork) / 60, sum(PlanMinNetwork) % 60) as PlanMin, FORMATMESSAGE('%d:%02d', sum(FactMinNetwork) / 60, sum(FactMinNetwork) % 60) as FactMin, CONVERT(XML, ( 
	SELECT City, FORMATMESSAGE('%d:%02d', sum(PlanMinNetwork) / 60, sum(PlanMinNetwork) % 60) as PlanMin, FORMATMESSAGE('%d:%02d', sum(FactMinNetwork) / 60, sum(FactMinNetwork) % 60) as FactMin, CONVERT(XML, ( 
		SELECT Network, FORMATMESSAGE('%d:%02d', PlanMinNetwork / 60, PlanMinNetwork % 60) as PlanMin, FORMATMESSAGE('%d:%02d', FactMinNetwork / 60, FactMinNetwork % 60) as FactMin
		FROM RawData networkData 
		WHERE networkData.cityId = cityData.cityId 
		ORDER BY Network 
		for xml path('item'), root ('items') 
		)) 
	FROM RawData cityData 
	WHERE CityData.regionId = RegionData.regionId 
	GROUP BY CityId, City 
	ORDER BY City 
	for xml path('item'), root ('items') 
	)) 
FROM RawData as RegionData 
GROUP BY RegionId, Region 
ORDER BY Region 
for xml path('item'), root ('items') 
