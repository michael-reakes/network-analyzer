create table Traffic (ID, Time, Source_IP, Destination_IP, Protocol, Length, Source_MAC, Destination_MAC, Interface);
create table Month (Number, Short);
insert into Month (Number, Short) Values (1, 'Jan');
insert into Month (Number, Short) Values (2, 'Feb');
insert into Month (Number, Short) Values (3, 'Mar');
insert into Month (Number, Short) Values (4, 'Apr');
insert into Month (Number, Short) Values (5, 'May');
insert into Month (Number, Short) Values (6, 'Jun');
insert into Month (Number, Short) Values (7, 'Jul');
insert into Month (Number, Short) Values (8, 'Aug');
insert into Month (Number, Short) Values (9, 'Sep');
insert into Month (Number, Short) Values (10, 'Oct');
insert into Month (Number, Short) Values (11, 'Nov');
insert into Month (Number, Short) Values (12, 'Dec');
create table Upload (Interface, Day, Source_MAC, Destination_IP, Length);
create table Download (Interface, Day, Destination_MAC, Source_IP, Length);
create table MAC (Address, Name);
insert into MAC (Address, Name) Values ('38:59:F9:2B:14:AC',"Leah's Work Computer");
insert into MAC (Address, Name) Values ('04:54:53:05:5B:85',"Michael's iMac");
insert into MAC (Address, Name) Values ('20:c9:d0:85:19:2d',"Leah's Macbook Pro");
insert into MAC (Address, Name) Values ('28:e7:cf:e6:23:23',"Michael's Apple TV");
insert into MAC (Address, Name) Values ('00:24:36:EC:46:CE',"Michael's Macbook Air");
insert into MAC (Address, Name) Values ('CC:3A:61:92:E7:42',"Michael's Galaxy S4");
insert into MAC (Address, Name) Values ('5C:96:9D:18:A8:A5',"Michael's iPad");
insert into MAC (Address, Name) Values ('a4:67:06:b2:b9:49',"Leah's iPad");
insert into MAC (Address, Name) Values ('28:37:37:20:12:40',"Philip's Macbook Air");
insert into MAC (Address, Name) Values ('10:9A:DD:AA:AB:5C',"Justin's Macbook Air");
create table IP (Address, Name);
create table TotalUsage (Day, Upload, Download, Total);


update TotalUsage tu set Upload = (select sum(u.Length) from Upload u where u.Day = date('now')), Download = (select sum(d.Length) from Download d where d.Day = date('now')), Total = (select sum(u.Length) from Upload u where u.Day = date('now'))+(select sum(d.Length) from Download d where d.Day = date('now')) where tu.Day = date('now');

# Yesterday's uploads by machine
select ifnull(m.Name,u.Source_MAC), SUM(u.Length)/1024/1024 from Upload u left join MAC m on u.Source_MAC = m.Address where u.Day = date('now', '-1 day') and u.Interface = '0' group by m.Name order by sum(Length) desc;

# Yesterday's downloads by machine
select ifnull(m.Name,d.Destination_MAC), SUM(d.Length)/1024/1024 from Download d left join MAC m on d.Destination_MAC = m.Address where d.Day = date('now', '-1 day') and d.Interface = '0' group by m.Name order by sum(Length) desc;

# Today's uploads by machine
select ifnull(m.Name,u.Source_MAC), SUM(u.Length)/1024/1024 from Upload u left join MAC m on u.Source_MAC = m.Address where u.Day = date('now') and u.Interface = '0' group by m.Name order by sum(Length) desc;

# Today's downloads by machine
select ifnull(m.Name,d.Destination_MAC), SUM(d.Length)/1024/1024 from Download d left join MAC m on d.Destination_MAC = m.Address where d.Day = date('now') and d.Interface = '0' group by m.Name order by sum(Length) desc;

# Yesterday's downloads and uploads


# Today's downloads and uploads


