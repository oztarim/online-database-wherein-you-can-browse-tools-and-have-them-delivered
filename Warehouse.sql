--clear everything from database 
begin
for trec in (select table_name from user_tables )
loop
execute immediate 'drop table '||trec.table_name||' cascade constraints';
end loop;
end;
/ 

begin
for trec in ( select type_name from user_types )
loop
execute immediate 'drop type '||trec.type_name||' force';
end loop;
end;
/ 
---------------------------------------
drop table product_table;
drop table supplier_table;
drop table address_table;
drop table orders_table;
drop table ships_table;
drop table shoppingcart_table;
drop table warehousestaff_table;
drop table officestaff_table;
drop table employee_table;
drop table handler_table;
drop table customer_table;
drop table delivery_table;
--------------------------------------
select * from product_table;
select * from supplier_table;
select * from address_table;
select * from orders_table;
select * from ships_table;
select * from shoppingcart_table;
select * from warehousestaff_table;
select * from officestaff_table;
select * from employee_table;
select * from handler_table;
select * from customer_table;
select * from delivery_table;
-------------------------------------
--start of sql code 
--*Payment object 
create type payment as object (PaymentID char(15), Pcardname varchar(30), Pcardnum char(10));
/
--CUSTOMER object
create type customer as object ( Cid char(2), Fname varchar(15), Lname varchar(15), Phone varchar(15), DateOfBirth date, RegistrationDate date, customerpayment payment, map member function MembershipDuration return integer, member function CustomerAge return integer, member function fullName return varchar);
/        
--methods for customer object
create type body customer as map member function  MembershipDuration return integer
is
begin
return sysdate -self.RegistrationDate;
end;
member function CustomerAge return integer
is 
begin   
return round((sysdate - self.DateOfBirth)/365,0);
end;
member function fullName return varchar
is
begin
return self.Fname||' '||self.LName;
end;
end; 
/
-- Xaddress object 
create type address as object  (AddressID char(2),StreetNumber char(4), StreetName char(15), City varchar(10), Province varchar(10), PostalCode varchar(10), Cid ref customer, member function fulladdress return varchar);
/
-- method for address object
create type body address as member function fulladdress return varchar
is
begin
return self.StreetNumber||' '||self.StreetName||' '||self.City||' '||self.Province||' '||self.PostalCode;
end;
end;
/
--DELIVERY bank 
create type delivery as object ( deliveryID char(2), DateDelivered date, DatePickedUp date, AddressID ref address, Cid ref customer, member function TotalDeliveryTime return integer);
/
--method for delivery object 
create type body delivery as member function TotalDeliveryTime return integer
is
begin
return self.DateDelivered - self.DatePickedUp;
end;
end;
/
--Xcreate supplier object 
create type supplier as object (Sid char(2), Sname varchar(15));
/
--Xcreate product object -- Order method requirs (arg arg-type)
create type product as object (Pid char(2), Pname varchar2(15), StockRentedOut varchar(20), StockTotal varchar(2), StockOnHand varchar(20), Sid ref supplier, member function checkStockOnHand return integer, order member function checkStockNeeded (pt in product) return integer);
/
--method for product object (works)
create type body product as 
member function checkStockOnHand return
integer 
is begin
return self.stockTotal - self.stockRentedOut;
end;
order member function checkStockNeeded(pt in product) return integer
is begin
if self.stockTotal < pt.stockTotal then return -1;
else if self.stockTotal > pt.stockTotal then return 1;
else return 0; 
end if;
end if;
end;
end;
/
--*create Employee object 
create type employee as object  (DepartmentID char(2), Lname varchar(15), Fname varchar(15), StartDate date, Salary varchar(15), Sid ref supplier, map member function LengthOfEmployment return integer, member function calculateSalary return integer);
/
--make employee object not final (since it is a class that other classes inherit)
alter type Employee not final
/
--create method for employee
create type body employee as map member function LengthOfEmployment
return integer
is
begin
return sysdate - self.startDate;
end;
member function calculateSalary return integer
is 
begin
return Salary;
end;
end; 
/
--Xcreate warehousestaff object 
create type warehouseStaff under employee (WarehouseID char(2), HoursWorked char(2), overriding member function calculateSalary return integer);
/ 
--XwarehouseStaff object overriding method
create type body warehouseStaff as overriding member function calculateSalary
return integer
is
begin
return self.HoursWorked * self.Salary;
end;
end;
/ 
--Xcreate officestaff object 
create type officeStaff under employee (OfficeID char(2));
/
--Xcreate product handler object 
create type product_handler as object  (HandlerID char(2), Pid ref product, warehouseID ref warehouseStaff, OfficeID ref OfficeStaff );
/ 
--Xcreate ORDERS object
create type orders as object  (Oid char(2), Odate date, OrderStatus varchar(15), ReturnByDate date, Cid ref customer, member function OrderETA return date, member function returnDateCalculation return date);
/
--method for orders object
create type body orders as member function returnDatecalculation return date
is
begin 
return self.Odate + 14;
end;
member function OrderETA return date
is begin
return self.ODate + 7;
end;
end;
/
--Xcreate ships object
create type ships as object (ShippingID char(2), ShippingMethod varchar(15), Pid ref product, deliveryID ref delivery);
/
--Xcreate shopping-cart object ++++++++++++++++
 create type shoppingcart as object (CartID char(2), Quantity char(5), sprice char(6), Pid ref product, Oid ref orders, member function checkOrderTotal return integer);
/
--method for shoppingcart
create type body shoppingcart as 
member function checkOrderTotal return integer
is begin
return self.sprice * self.Quantity;
end;
end;
/
--creating object tables 
create table product_table of product (Pid primary key);
create table supplier_table  of supplier (Sid primary key);
create table orders_table  of orders (Oid primary key);
create table address_table  of address (AddressID primary key);
create table ships_table of ships (ShippingID primary key);
create table shoppingcart_table of shoppingcart (CartID primary key);
create table warehousestaff_table of WarehouseStaff (WarehouseID primary key);
create table officestaff_table  of OfficeStaff (OfficeID primary key);
create table employee_table  of Employee (DepartmentID primary key);
create table handler_table  of product_handler (HandlerID primary key);
create table customer_table of customer (Cid primary key);
create table delivery_table of delivery (DeliveryID primary key);

--starting to populate tables 
--populating customer table (NO REFERENCES)

insert into customer_table values (customer('01','Ahmed','Appleboy', '5554206969','22-Jan-1998','09-Jun-2021', payment('33','Visa', '5555-99999')));
insert into customer_table values (customer('02','Ozgur','AndroidFace', '5554209696','30-Nov-1997','08-Mar-2021', payment('35','Mastercard', '6666-99999')));
insert into customer_table values (customer('03','Bob','Doesntwork', '5554209696','23-Jun-2008','09-Nov-2021', payment('55','AMEX', '7777-99999')));
insert into customer_table values (customer('04','Mike','Myers', '5554209996','24-Feb-1919','09-Jul-2021', payment('37','Bitcoin', '8888-99999')));

--populating address table
insert into address_table values (address('01', '21', 'Weston Road', 'Toronto', 'Ontario', 'M9M1T3', 
(select ref(c) from customer_table c where c.Cid = '01')));

insert into address_table values (address('02', '31', 'Wilson Avenue', 'Toronto', 'Ontario', 'M3J6T5', 
(select ref(c) from customer_table c where c.Cid = '02')));

insert into address_table values (address('03', '41', 'Clark Avenue', 'Niagara', 'Ontario', 'L2G3W4', 
(select ref(c) from customer_table c where c.Cid = '03')));

insert into address_table values (address('04', '12', 'Patrick Street', 'Stratford', 'Ontario', 'N5A0C1', 
(select ref(c) from customer_table c where c.Cid = '04'))); 

--populating delivery table
insert into delivery_table values (delivery('01', '25-Feb-2021', '21-Feb-2021', 
(select ref(a) from address_table a where a.AddressID = '01'),
(select ref(c) from customer_table c where c.Cid = '01')));

insert into delivery_table values (delivery('02', '26-Mar-2021', '22-Mar-2021', 
(select ref(a) from address_table a where a.AddressID = '02'),
(select ref(c) from customer_table c where c.Cid = '02')));

insert into delivery_table values (delivery('03', '27-Apr-2021', '23-Apr-2021', 
(select ref(a) from address_table a where a.AddressID = '03'),
(select ref(c) from customer_table c where c.Cid = '03')));

insert into delivery_table values (delivery('04', '28-May-2021', '24-May-2021', 
(select ref(a) from address_table a where a.AddressID = '04'),
(select ref(c) from customer_table c where c.Cid = '04')));

--populating orders table (without ORDER TIME) 
insert into orders_table values(orders('01', '02-Feb-2021', 'Delivered!', '02-Mar-2021', 
(SELECT ref(c) from customer_table c WHERE c.cid = '01')));

insert into orders_table values(orders('02', '03-Mar-2021', 'On the Way!', '14-Mar-2021',
(SELECT ref(c) from customer_table c WHERE c.cid = '02')));

insert into orders_table values(orders('03', '04-Apr-2021', 'Order Ready!', '07-May-2021',
(SELECT ref(c) from customer_table c WHERE c.cid = '03')));

insert into orders_table values(orders('04', '05-May-2021', 'Delivered!', '05-Jun-2021',
(SELECT ref(c) from customer_table c WHERE c.cid = '04')));

--populating supplier table 
insert into supplier_table values (supplier('01', 'Ryobi'));
insert into supplier_table values (supplier('02', 'AlphaSigma'));
insert into supplier_table values (supplier('03', 'BlackDecker'));
insert into supplier_table values (supplier('04', 'Stuart Weitzman'));

--populating product object 
insert into product_table values (product('99', 'Chainsaw num1','44', '20','21',
(select ref(s) from supplier_table s where s.Sid = '01')));

insert into product_table values (product('66', 'Lawn Trimmer','44', '20','9',
(select ref(s) from supplier_table s where s.Sid = '02')));

insert into product_table values (product('77', 'Monkey Wrench', '44', '20','21',
(select ref(s) from supplier_table s where s.Sid = '03')));

insert into product_table values (product('55', 'Shovel1', '44', '20','8',
(select ref(s) from supplier_table s where s.Sid = '04')));

--populating shopping cart table 
insert into shoppingcart_table values(shoppingcart('31','06', '66',
(select ref(p) from product_table p where p.Pid = '99'),
(select ref(o) from orders_table o where o.Oid = '01')));

insert into shoppingcart_table values(shoppingcart('32', '05','70',
(select ref(p) from product_table p where p.Pid = '66'),
(select ref(o) from orders_table o where o.Oid = '02')));

insert into shoppingcart_table values(shoppingcart('33','09','80',
(select ref(p) from product_table p where p.Pid = '77'),
(select ref(o) from orders_table o where o.Oid = '03')));

insert into shoppingcart_table values(shoppingcart('34','07','90',
(select ref(p) from product_table p where p.Pid = '55'),
(select ref(o) from orders_table o where o.Oid = '04')));

--populating ships table 
insert into ships_table values (ships('01','express',
(select ref (p) from product_table p where p.Pid = '99'),
(select ref (d) from delivery_table d where d.deliveryID = '01')));

insert into ships_table values (ships('02', 'courier',
(select ref (p) from product_table p where p.Pid='66'),
(select ref (d) from delivery_table d where d.deliveryID = '02')));

insert into ships_table values (ships('03', 'express',
(select ref (p) from product_table p where p.Pid='77'),
(select ref (d) from delivery_table d where d.deliveryID = '03')));

insert into ships_table values (ships('04', 'express',
(select ref (p) from product_table p where p.Pid= '55'),
(select ref (d) from delivery_table d where d.deliveryID = '04')));

--populating warehouse table (NO REFERENCES)
insert into warehousestaff_table values (warehouseStaff('40','Philbin','Darrel','08-Aug-2001','25',(select ref(s) from supplier_table s where s.Sid = '01'),'45','23'));
insert into warehousestaff_table values (WarehouseStaff('67','Jordan','Michael','19-Nov-2021','35',(select ref(s) from supplier_table s where s.Sid = '02'),'50','44'));
insert into warehousestaff_table values (WarehouseStaff('65','Malone', 'Kevin','05-May-2010','30',(select ref(s) from supplier_table s where s.Sid = '03'),'55','34'));
insert into warehousestaff_table values (warehouseStaff('40','Homer','Simpson','09-Nov-2021','50',(select ref(s) from supplier_table s where s.Sid = '04'),'60','68'));

--populating officestaff table (NO REFERENCES)
insert into officestaff_table values (OfficeStaff('35', 'Mann', 'David', '06-Sep-2020','45000',(select ref(s) from supplier_table s where s.Sid = '01'),  '78'));
insert into officestaff_table values (OfficeStaff('36', 'Smith', 'Alex', '08-Oct-2020','45000',(select ref(s) from supplier_table s where s.Sid = '02'),  '99'));
insert into officestaff_table values (OfficeStaff('37', 'Bond', 'Megan', '17-Aug-2020','45000',(select ref(s) from supplier_table s where s.Sid = '03'), '69'));
insert into officestaff_table values (OfficeStaff('38', 'Johnson', 'Angelina', '14-Feb-2020','45000',(select ref(s) from supplier_table s where s.Sid = '04'), '89')); 

--populating product_handler table 
insert into handler_table values (product_handler('22', (select ref(p) from product_table p where p.Pid = '55'), (select ref (ws) from warehousestaff_table ws where ws.warehouseID = '45'), (select ref (o) from officestaff_table o where o.OfficeID = '78')));

insert into handler_table values (product_handler('23', (select ref(p) from product_table p where p.Pid = '66'), (select ref(ws) from warehousestaff_table ws where ws.warehouseID= '50'), (select ref (o) from officestaff_table o where o.OfficeID = '99')));

insert into handler_table values(product_handler('24', (select ref(p) from product_table p where p.Pid = '77'), (select ref (ws) from warehousestaff_table ws where ws.warehouseID= '55'), (select ref (o) from officestaff_table o where o.OfficeID = '89')));

insert into handler_table values(product_handler('25', (select ref(p) from product_table p where p.Pid = '99'), (select ref(ws) from warehousestaff_table  ws where ws.warehouseID= '60'), (select ref (o) from officestaff_table o where o.OfficeID = '69')));

--Working Queries
--# 1. Find the names of Customers that ordered products from Supplier "Stuart Weitzman".

select sc.oid.cid.fullName() as Name from  shoppingcart_table sc where sc.pid.sid.sname like '%Weitzman%';

--#2. Find the address of the customers and order them by how long they've been a member

select a.cid.fullName() as Name, a.fulladdress() as address from address_table a order by a.cid.MembershipDuration();

--#3. Find the delivery dates of customers in Toronto 

select d.DateDelivered as D_Date from delivery_table d where d.AddressID.City = 'Toronto';

--#4. Find the weekly salary of the Warehouse Worker who handles the supplier AlphaSigma

select wh.fname,wh.lname,wh.calculateSalary() as weekly_salary from warehousestaff_table wh where wh.sid.sname like'%AlphaSigma%';

--#5 find the office workers who handles the product monkey wrench

select ph.OfficeID.fname as first, ph.OfficeID.lname as last from handler_table ph where ph.pid.pname like'%Monkey%';

--#6 Get supplier name of and compare instance of the lawntrimmer in our database with an instance that has our preferred Total stocklevel of 25 and see if it needs to be restocked ?

select p.sid.sname as Supplier_Name, p.checkStockNeeded(product('66', 'Lawn Trimmer','44', '199','9', (select ref(s) from supplier_table s where s.Sid = '02'))) as negative_for_restock from product_table p where p.pid = '66';

--#7. Find the number of orders that belong to a customerID. 
--(REMINDER: Cap Name in Customer Table to varchar(20))
 
SELECT o.Cid.cid as cid, o.Cid.fullName() as Name, Count(o.Oid) AS CountOrders FROM orders_table o Where o.Cid = o.Cid GROUP BY o.Cid Order BY CountOrders;

--#8 Which products are included in a deliveries in 2021 between January and March

select sh.pid.pname as p_name, sh.deliveryID.deliveryID as ID from ships_table sh where sh.deliveryID.DateDelivered Between '31-Dec-2020' AND '01-Apr-2021';

--#9 Print all customers  with delivered order status 

select o.cid.fullName() as Name from orders_table o where o.OrderStatus = 'Delivered!';

--#10 Find the shipping method for each customer under 30

SELECT sh.Shippingmethod, sh.deliveryID.cid.fullName() as Name from ships_table sh where sh.deliveryID.Cid.CustomerAge() < 30; 

--#11 Find the total of each orders containing only chainsaws 

select sc.checkOrderTotal() as total_amount, sc.oid.oid as id from shoppingcart_table sc where sc.pid.pname like '%Chainsaw%';

--#12 Find all payment methods for deliveries in toronto

select d.cid.customerPayment.Pcardname as payment_type, d.cid.fullName() as Name from delivery_table d where d.AddressID.city like '%Toronto%';

--#13 Find the orderETA for customers who ordered chainsaws

select sc.oid.cid.fullName() as name, sc.oid.OrderETA() as ETA from shoppingcart_table sc  where sc.pid.pname like '%Chainsaw%';

